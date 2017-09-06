# Andriod Linker原理

> 2017-02-09, beijing, @elemeta

linker是个动态链接器，也叫解析器，用来对执行的elf可执行前的so文件加载和重定位。
`PT_INTERP`中指定了解析器的路径。

## load_elf_binary

该函数是内核函数，在内核代码的fs/binfmt_elf.c中。一个程序的执行是从execve系统
调用开始的，如果我们执行的是elf格式的文件，最终会调用`load_elf_binary`函数做实际
的加载，该函数进行如下操作：

1. 检查elf文件格式是否合法；
2. 查找解析器（`PT_INTERP`程序段），如果找到了就加载到内存中；
3. 把程序的`PT_LOAD`程序段加载到内存中，并设置栈信息。
4. 如果有解析器的把解析器的`PT_LOAD`程序段加载到内存，并从解析器的entry开始执行程序。

设置栈信息的函数是`create_elf_tables`，栈信息包括argc、argv[]、envp[]、aux
信息等，设置好的栈结构如下：

        +-------------------+ # 栈底，向下增长
        | ELF_PLATFORM      | # uname -m 得到的字符串，带0结束符
        | ELF_BASE_PLATFORM | # 字符串，带0结束符
        | 伪随机数种子       | # 16字节固定大小
        | AUX数据           | # Elf_Verdaux数组且最后一项是NULL
        | envp 数组         | # 环境变量数组，最后一项是NULL
        | argv 数组         | # 参数数组，最后一项是NULL
        | argc              | # 参数个数


## __linker_init

该函数在android中bionic库中，位置是`linker/linker_main.cpp`。其实真正的入口是
arch/begin.S中的`_start`函数

        ENTRY(_start)
        mov r0, sp
        bl __linker_init

        /* linker init returns the _entry address in the main image */
        bx r0
        END(_start)
    
真正的工作还是在`__linker_init`中完成的，最后再跳转到主程序的入口处继续执行。该函数
的参数就是当前的栈顶指针(sp)。

linker本身就是个so文件，要让自己能够正常使用需要先给自己重定位一下。`linker_so`变
量就表示自己，
 
        linker_so.base = linker_addr;
        linker_so.size = phdr_table_get_load_size(phdr, elf_hdr->e_phnum);
        linker_so.load_bias = get_elf_exec_load_bias(elf_hdr);
        linker_so.dynamic = nullptr;
        linker_so.phdr = phdr;
        linker_so.phnum = elf_hdr->e_phnum;
        linker_so.set_linker_flag();

        linker_so.prelink_image())
        linker_so.link_image(g_empty_list, g_empty_list, nullptr)) // 重定位
    
重定位完之后先进行一些初始化操作，然后继续去处理剩下的事情。

        // Initialize the main thread (including TLS, so system calls really work).
        __libc_init_main_thread(args);
    
        linker_so.call_constructors();  // 调用自己的init函数
        sonext = solist = get_libdl_info(kLinkerPath); // 把自己添加到solist中，这样dlopen、dlsym、doclose函数就可以使用了
        
        ElfW(Addr) start_address = __linker_init_post_relocation(args, linker_addr); // 做剩下的事情
        return start_address; // 返回原来程序的入口地址，继续执行

## __linker_init_post_relocation

该函数加载vdso模块到solist中，解析源程序的依赖关系，并递归的将所有的依赖so都
加载到内存中，并重定位，最后返回源程序的入口地址。

1. 先把主程序somain变量中。

        const char* executable_path = get_executable_path();
        soinfo* si = soinfo_alloc(&g_default_namespace, executable_path, &file_stat, 0, RTLD_GLOBAL);
        
        somain = si;
        
        si->prelink_image()
    
2. 加载主程序依赖的模块，Linux中程序说依赖的模块名称会在`DT_NEEDED`程序段中填写。

        // LD_PRELOAD优先加载
        for (const auto& ld_preload_name : g_ld_preload_names) {
            needed_library_name_list.push_back(ld_preload_name.c_str());
            ++ld_preloads_count;
        }
        
        // DT_NEEDED程序段中制定的模块
        for_each_dt_needed(si, [&](const char* name) {
            needed_library_name_list.push_back(name);
        });
        
        // 查找并加载依赖的模块
        if (needed_libraries_count > 0 &&
                !find_libraries(&g_default_namespace, si, needed_library_names, needed_libraries_count,
                                nullptr, &g_ld_preloads, ld_preloads_count, RTLD_GLOBAL, nullptr,
                                /* add_as_children */ true)) {
            __libc_fatal("CANNOT LINK EXECUTABLE \"%s\": %s", g_argv[0], linker_get_error_buffer());
        } else if (needed_libraries_count == 0) {
            if (!si->link_image(g_empty_list, soinfo_list_t::make_list(si), nullptr)) {
                __libc_fatal("CANNOT LINK EXECUTABLE \"%s\": %s", g_argv[0], linker_get_error_buffer());
            }
            si->increment_ref_count();
        }
        
        add_vdso(args); // 添加[vdso]模块
    
3. 调用init函数

        si->call_pre_init_constructors();
        si->call_constructors();
 
4. 返回主程序的入口地址

        ElfW(Addr) entry = args.getauxval(AT_ENTRY);
        return entry;
    
## find_libraries

该函数在linker/linker.cpp中，该函数不仅查找所有的依赖库，还完成加载到内存和重定向。

    for (size_t i = 0; i < library_names_count; ++i) {
        const char* name = library_names[i];
        load_tasks.push_back(LoadTask::create(name, start_with, &readers_map));
    }
    
    for (size_t i = 0; i<load_tasks.size(); ++i) {
        LoadTask* task = load_tasks[i];
        
        if(!find_library_internal(ns, task, &zip_archive_cache, &load_tasks, rtld_flags)) {
            return false;
        }
    
    
`find_library_internal`查找so是否已经加载，如果没有就加载它,这里只是加载到内存，尚未重定向
    
## add_vdso

主进程栈的AUX信息里`AT_SYSINFO_EHDR`项就是vdso的基地址

        static void add_vdso(KernelArgumentBlock& args __unused)
        {
            #if defined(AT_SYSINFO_EHDR)
            ElfW(Ehdr)* ehdr_vdso = reinterpret_cast<ElfW(Ehdr)*>(args.getauxval(AT_SYSINFO_EHDR));
            if (ehdr_vdso == nullptr) {
                return;
            }

            soinfo* si = soinfo_alloc(&g_default_namespace, "[vdso]", nullptr, 0, 0);

            si->phdr = reinterpret_cast<ElfW(Phdr)*>(reinterpret_cast<char*>(ehdr_vdso) + ehdr_vdso->e_phoff);
            si->phnum = ehdr_vdso->e_phnum;
            si->base = reinterpret_cast<ElfW(Addr)>(ehdr_vdso);
            si->size = phdr_table_get_load_size(si->phdr, si->phnum);
            si->load_bias = get_elf_exec_load_bias(ehdr_vdso);

            si->prelink_image();
            si->link_image(g_empty_list, soinfo_list_t::make_list(si), nullptr);
            #endif
        }
    
## prelink_image

该函数主要解析.dynamic区块中的信息，他是进行链接的重要信息，包括符号信息、重定位信息，so依赖关系、字符串信息等等的索引。

## link_image

该函数进行正式的链接过程，包括递归加载依赖的so，进行重定位。

