# Linux内核驱动加载过程

> elemeta, elemeta47@gmail.com

##　0x00 概述
无论是init_module,还是finit_module系统调用,开始加载模块的起点都是load_module函数，下面列出驱动加载的关键流程（以官方的Linux 4.7为例）

    // src/kernel/module.c
    sys_init_module:->{
        struct load_info info;
        // copy模块文件到内核空间，info->hdr指向模块头部，info->len为模块的大小
        copy_module_from_user(umod, len ,&info); 
        return load_module:->{
            struct module *mod;
            // 检查签名 [CONFIG_MODULE_SIG]
            module_sig_check(info);
            // 检查模块映象的文件头是否合法(magic,type,arch,shoff)
            elf_header_check(info);
            //加载模块的各区段,创建struct module
            mod = layout_and_allocate:->{
                // 重新定位代码和数据的地址。
                mod = setup_load_info(info);
                // 检查模块的合法性，比如：vermagic，license
                check_modinfo(mod, info, 0);
                // 继续初始化mod
                layout_sections(mod, info);
                layout_symtab(mod, info);
            }
            // 添加mod到全局模块链表中，并标记为MODULE_STATE_UNFORMED
            add_unformed_module(mod);
            ......
            //释放掉info，现在内容已经保存在mod中了
            return do_init_module:->{
                // 调用自己的模块初始化函数，既hello_init();
                do_one_initcall(mod->init);
                // 设置模块状态为MODULE_STATE_LIVE
            }
        }
    }

##　0x01 .ko文件的布局
    +----------+
    | 文件头   |
    | 区块头   |
    | 数据部分 |
    | 签名信息 |
    +----------+
这里区块头不一定是紧挨在文件头的后面，要看文件头的e_shoff的值决定，由于模块是重定位类型的文件，所有没有程序头，即e_phoff为0.

## 0x02 签名验证
笔者的Linux版本是支持数字签名的，验证的函数是module_sig_check，如果签名失败就拒绝加载模块。签名数据附加在在ko文件的末尾，长度为module_signature.sig_len +  sizeof(struct module_signature) + strlen(MODULE_SIG_STRING)，布局如下图所示：

    +-------------------------+
    | 正常的ELF文件           |
    +-------------------------+
    | 签名数据                | ;module_signature.sig_len
    | struct module_signature | ;sizeof(struct module_signature)
    | MODULE_SIG_STRING       | ;strlen(MODULE_SIG_STRING)
    +-------------------------+

MODULE_SIG_STRING相当于签名数据的magic，值为字符串"~Module signature appended~\n"。在文件的结尾匹配到它说明包含签名信息，紧挨着该字符串前头是一个struct module_signature结构体，描述了数字签名的头部，紧挨着该结构体的前module_signature.sig_len个字节数据就是数字签名的内容了验证签名数据的函数是 verify_pkcs7_signature。

## 0x03 加载各区块
所有带有SHF_ALLOC标记的区块都会被依次复制到module.core_layout.base所在的内存中，带有INIT_OFFSET_MASK位的区块会加载到module.init_layout.base所在内存，因为这里是init函数。参考layout_and_allocate函数。

## 0x04 符号表（SHT_SYMTAB）
他的作用相当于PE中的IAT，专门有一个区块保存符号表，区块类型为SHT_SYMTAB。他是一个Elf_Sym类型的数组：

    typedef struct
    {
      Elf32_Word	st_name;		/* 符号名称索引 */
      Elf32_Addr	st_value;		/* 符号地址，待加载器赋值 */
      Elf32_Word	st_size;		/* Symbol size */
      unsigned char	st_info;		/* Symbol type and binding */
      unsigned char	st_other;		/* Symbol visibility */
      Elf32_Section	st_shndx;		/* Section index */
    } Elf32_Sym;

在加载模块的过程中，要遍历每个Elf_Sym结构体，根据st_name查找的的符号地址复制给st_value，参见simplify_symbols函数。

## 0x05 地址重定位
代码段和数据段中引用到的符号地址需要在加载时重定位，区块类型是SHT_REL或者SHT_RELA的都是重定位数据块。每个重定位区块负责对一个区块进行重定位，重定位块的Elf_Shdr.sh_info标识它是属于哪一个区块的重定位信息。Elf32_Rel.r_offset表示区块内的偏移量。Elf32_Rel.r_info的高24位表示对应的符号在符号表中的偏移，这样就可以找到向前已经加载好的符号的真实地址了。参见apply_relocations函数。

## 0x06 其他细节

- 如果加载模块的过程中，该模块已经被加载或者正在加载中，那么直接退出。参见add_unformed_module函数。

- \__kcrctab和__ksymtab区块这里是模块导出的函数

- 笔者研究的linux版本还支持构造函数，会在module_init之前优先调用.ctors或者.init_array区块里的函数。
