<map version="1.0.1">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node COLOR="#000000" CREATED="1504503164512" ID="ID_380864189" MODIFIED="1504516226905" TEXT="Intel&#x624b;&#x518c;">
<font NAME="SansSerif" SIZE="20"/>
<hook NAME="accessories/plugins/AutomaticLayout.properties"/>
<node COLOR="#0033ff" CREATED="1504503240179" ID="ID_886753052" MODIFIED="1504667704871" POSITION="right" TEXT="&#x6a21;&#x5f0f;&#x5207;&#x6362;">
<edge STYLE="sharp_bezier" WIDTH="8"/>
<font NAME="SansSerif" SIZE="18"/>
<node COLOR="#00b439" CREATED="1504503246752" ID="ID_658332511" MODIFIED="1504504264096" TEXT="&#x5b9e;&#x6a21;&#x5f0f;-&gt;&#x4fdd;&#x62a4;&#x6a21;&#x5f0f;">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <p>
      &#35774;&#32622;CR0.PE=1&#21518;&#23601;&#21551;&#21160;&#20102;&#20445;&#25252;&#27169;&#24335;&#65307;&#21551;&#21160;&#20998;&#39029;&#26426;&#21046;&#26159;&#21487;&#36873;&#30340;CR0.PG=1
    </p>
  </body>
</html></richcontent>
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
<node COLOR="#990000" CREATED="1504503295961" ID="ID_1141007666" MODIFIED="1504503997330" TEXT="1.&#x7981;&#x6b62;&#x4e2d;&#x65ad;cli">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504503306677" ID="ID_461951142" MODIFIED="1504504222817" TEXT="2.&#x8bbe;&#x7f6e;gdtr(lgdt)">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <div style="color: #d4d4d4; background-color: #1e1e1e; font-family: Consolas, Courier New, monospace; font-weight: normal; font-size: 12px; line-height: 16px; white-space: pre">
      <div>
        <font color="#608b4e">/*</font>
      </div>
      <div>
        <font color="#608b4e">* This is the Global Descriptor Table</font>
      </div>
      <div>
        <font color="#608b4e">*</font>
      </div>
      <div>
        <font color="#608b4e">* An entry, a &quot;Segment Descriptor&quot;, looks like this:</font>
      </div>
      <div>
        <font color="#608b4e">*</font>
      </div>
      <div>
        <font color="#608b4e">* 31 24 19 16 7 0</font>
      </div>
      <div>
        <font color="#608b4e">* ------------------------------------------------------------</font>
      </div>
      <div>
        <font color="#608b4e">* | | |B| |A| | | |1|0|E|W|A| |</font>
      </div>
      <div>
        <font color="#608b4e">* | BASE 31..24 |G|/|0|V| LIMIT |P|DPL| TYPE | BASE 23:16 |</font>
      </div>
      <div>
        <font color="#608b4e">* | | |D| |L| 19..16| | |1|1|C|R|A| |</font>
      </div>
      <div>
        <font color="#608b4e">* ------------------------------------------------------------</font>
      </div>
      <div>
        <font color="#608b4e">* | | |</font>
      </div>
      <div>
        <font color="#608b4e">* | BASE 15..0 | LIMIT 15..0 |</font>
      </div>
      <div>
        <font color="#608b4e">* | | |</font>
      </div>
      <div>
        <font color="#608b4e">* ------------------------------------------------------------</font>
      </div>
      <div>
        <font color="#608b4e">*</font>
      </div>
      <div>
        <font color="#608b4e">* Note the ordering of the data items is reversed from the above</font>
      </div>
      <div>
        <font color="#608b4e">* description.</font>
      </div>
      <div>
        <font color="#608b4e">*/ </font>
      </div>
    </div>
    <div style="color: #d4d4d4; background-color: #1e1e1e; font-family: Consolas, Courier New, monospace; font-weight: normal; font-size: 12px; line-height: 16px; white-space: pre">
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.p2align&#160;&#160;&#160;&#160;</font><font color="#b5cea8">2</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#608b4e">/* force 4-byte alignment */</font>
      </div>
      <div>
        <font color="#569cd6">gdt</font><font color="#d4d4d4">:</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">byte</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <br />
      

      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* code segment */</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0xFFFF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">byte</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0x9A</font><font color="#d4d4d4">, </font><font color="#b5cea8">0xCF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <br />
      

      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* data segment */</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0xFFFF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">byte</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0x92</font><font color="#d4d4d4">, </font><font color="#b5cea8">0xCF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <br />
      

      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* 16 bit real mode CS */</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0xFFFF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">byte</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0x9E</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <br />
      

      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* 16 bit real mode DS */</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0xFFFF</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">byte</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0x92</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font><font color="#d4d4d4">, </font><font color="#b5cea8">0</font>
      </div>
      <br />
      <br />
      

      <div>
        <font color="#608b4e">/* this is the GDT descriptor */</font>
      </div>
      <div>
        <font color="#dcdcaa">gdtdesc:</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.</font><font color="#4ec9b0">word</font><font color="#d4d4d4">&#160;&#160;&#160;</font><font color="#b5cea8">0x27</font><font color="#d4d4d4">&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* limit */</font>
      </div>
      <div>
        <font color="#d4d4d4">&#160;&#160;&#160;&#160;.long&#160;&#160;&#160;</font><font color="#569cd6">gdt</font><font color="#d4d4d4">&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</font><font color="#608b4e">/* addr */</font>
      </div>
      <br />
      
    </div>
    <div style="color: #d4d4d4; background-color: #1e1e1e; font-family: Consolas, Courier New, monospace; font-weight: normal; font-size: 12px; line-height: 16px; white-space: pre">
      <div>
        
      </div>
    </div>
  </body>
</html></richcontent>
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504503333152" ID="ID_1003692911" MODIFIED="1504504113154" TEXT="3.&#x5f00;&#x542f;&#x4fdd;&#x62a4;&#x6a21;&#x5f0f;mov cr0, (1 &lt;&lt; CRO_PE)">
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504503952468" ID="ID_1293632236" MODIFIED="1504503997338" TEXT="&#x5206;&#x9875;&#x673a;&#x5236;CR0.PG&#x662f;&#x53ef;&#x9009;&#x7684;">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
<icon BUILTIN="messagebox_warning"/>
</node>
</node>
<node COLOR="#990000" CREATED="1504503384009" ID="ID_336279532" MODIFIED="1504667716238" TEXT="4.&#x9a6c;&#x4e0a;&#x6267;&#x884c;&#x4e00;&#x4e2a;far jmp/call, &#x7528;&#x6765;&#x5237;&#x65b0;prefetch-queue&#xff0c;&#x8bbe;&#x7f6e;CS">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <p>
      &#29992;&#26469;&#21047;&#26032;&#19968;&#19979;CPU&#30340;&#27969;&#27700;&#32447;&#21644;&#25351;&#20196;&#20248;&#21270;&#65292;&#21516;&#26102;&#21152;&#36733;CS&#23492;&#23384;&#22120;
    </p>
    <p>
      &#22914;&#26524;&#21551;&#21160;&#20102;&#20998;&#39029;&#26426;&#21046;&#65292;&#36825;&#37324;&#30340;&#22320;&#22336;&#35201;&#26159;&#32447;&#24615;&#22320;&#22336;&#30340;&#32034;&#24341;&#12290;
    </p>
  </body>
</html></richcontent>
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504503576587" ID="ID_1709052812" MODIFIED="1504503997341" TEXT="5.&#x8bbe;&#x7f6e;DS&#x3001;SS&#x3001;ES&#x3001;FS&#x3001;GS&#x4e3a;&#x6307;&#x5411;&#x6570;&#x636e;&#x6bb5;">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504503700102" ID="ID_583094364" MODIFIED="1504503997343" TEXT="6.&#x8bbe;&#x7f6e;&#x65b0;&#x7684;&#x4e2d;&#x65ad;IDTR(ldtr)">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504503683833" ID="ID_1891423427" MODIFIED="1504503997344" TEXT="7.&#x6253;&#x5f00;&#x4e2d;&#x65ad;sti">
<font NAME="SansSerif" SIZE="14"/>
</node>
</node>
<node COLOR="#00b439" CREATED="1504503254296" ID="ID_1718282196" MODIFIED="1504504294607" TEXT="&#x4fdd;&#x62a4;&#x6a21;&#x5f0f;-&gt;&#x5b9e;&#x6a21;&#x5f0f;">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <p>
      &#35774;&#32622;CR0.PE=0&#23601;&#25913;&#22238;&#20102;&#23454;&#27169;&#24335;
    </p>
  </body>
</html></richcontent>
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
<node COLOR="#990000" CREATED="1504504313699" ID="ID_1692484394" MODIFIED="1504504320971" TEXT="1.&#x7981;&#x6b62;&#x4e2d;&#x65ad;cli">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504504321288" ID="ID_683135341" MODIFIED="1504504335434" TEXT="2.&#x7981;&#x7528;&#x5206;&#x9875;">
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504504664029" ID="ID_1462547633" MODIFIED="1504504684108" TEXT="1.&#x6e05;&#x9664;CR0.PG&#x4f4d;"/>
<node COLOR="#111111" CREATED="1504504684338" ID="ID_1844340340" MODIFIED="1504504707757" TEXT="2.&#x5237;&#x65b0;&#x5757;&#x8868;(mov cr3, 0x0)"/>
</node>
<node COLOR="#990000" CREATED="1504504335731" ID="ID_395289447" MODIFIED="1504505027324" TEXT="3.&#x5207;&#x6362;&#x63a7;&#x5236;&#x6d41;&#x5728;1MB&#x5bfb;&#x5740;&#x8303;&#x56f4;&#x5185;">
<richcontent TYPE="NOTE"><html>
  <head>
    
  </head>
  <body>
    <p>
      &#8212; Limit = 64 KBytes (0FFFFH)<br />&#8212; Byte granular (G = 0)<br />&#8212; Expand up (E = 0)<br />&#8212; Writable (W = 1)<br />&#8212; Present (P = 1)<br />&#8212; Base = any value<br align="-webkit-auto" style="font-variant: normal; letter-spacing: normal; line-height: normal; text-indent: 0px; text-transform: none; white-space: normal; word-spacing: 0px" />
    </p>
  </body>
</html></richcontent>
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504504804122" ID="ID_1824766437" MODIFIED="1504504948142" TEXT="1.&#x786e;&#x4fdd;&#x6709;&#x4e00;&#x4e2a;limit=64Kb&#x7684;&#x4ee3;&#x7801;&#x6bb5;&#x548c;&#x6570;&#x636e;&#x6bb5;"/>
<node COLOR="#111111" CREATED="1504504902045" ID="ID_88848223" MODIFIED="1504504951616" TEXT="2.&#x4f7f;&#x7528;far jmp&#x6765;&#x52a0;&#x8f7d;CS"/>
<node COLOR="#111111" CREATED="1504504349942" ID="ID_1016844762" MODIFIED="1504504972402" TEXT="3.&#x91cd;&#x7f6e;SS&#x3001;DS&#x3001;ES&#x3001;FS&#x3001;GS&#x5230;1&#x7684;&#x6570;&#x636e;&#x6bb5;">
<font NAME="SansSerif" SIZE="12"/>
</node>
</node>
<node COLOR="#990000" CREATED="1504504376573" ID="ID_675142737" MODIFIED="1504504406196" TEXT="5.&#x52a0;&#x8f7d;&#x5b9e;&#x6a21;&#x5f0f;&#x4e2d;&#x65ad;&#x8868;(LIDT)">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504504408425" ID="ID_1838264612" MODIFIED="1504505102865" TEXT="6.&#x6e05;&#x9664;CR0.PE&#x4f4d;&#xff0c;&#x8fdb;&#x5165;&#x5b9e;&#x6a21;&#x5f0f;">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504504429175" ID="ID_1047439580" MODIFIED="1504668003965" TEXT="7.far jmp&#xff0c;&#x91cd;&#x7f6e;&#x5b9e;&#x6a21;&#x5f0f;&#x7684;CS&#x548c;&#x91cd;&#x7f6e;prefetch-queue">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504504436724" ID="ID_74397424" MODIFIED="1504505182751" TEXT="8.&#x91cd;&#x7f6e;SS&#x3001;DS&#x3001;ES&#x3001;FS&#x3001;GS&#x4e3a;&#x5b9e;&#x6a21;&#x5f0f;&#x6bb5;">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504504440262" ID="ID_1090275538" MODIFIED="1504504449368" TEXT="9.&#x6253;&#x5f00;&#x4e2d;&#x65ad;sti">
<font NAME="SansSerif" SIZE="14"/>
</node>
</node>
</node>
<node COLOR="#0033ff" CREATED="1504516211760" ID="ID_1165989177" MODIFIED="1504517479344" POSITION="right" TEXT="APIC">
<edge STYLE="sharp_bezier" WIDTH="8"/>
<font NAME="SansSerif" SIZE="18"/>
<node COLOR="#00b439" CREATED="1504516247011" ID="ID_1688959251" MODIFIED="1504516251323" TEXT="Local APIC">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
<node COLOR="#990000" CREATED="1504516334753" ID="ID_728067815" MODIFIED="1504516371731" TEXT="Local APIC&#x5bc4;&#x5b58;&#x5668;">
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504516372744" ID="ID_909839945" MODIFIED="1504519221550" TEXT="&#x6620;&#x5c04;&#x5230;&#x5185;&#x5b58;&#x7a7a;&#x95f4;&#xff0c;&#x7528;mov&#x8bfb;&#x5199;"/>
<node COLOR="#111111" CREATED="1504519214871" ID="ID_1473670370" MODIFIED="1504519386788" TEXT="4K&#x5b57;&#x8282;&#x533a;&#x57df;&#xff0c;&#x521d;&#x59cb;&#x542f;&#x52a8;&#x5730;&#x5740;&#xff1a;FEE00000H">
<node COLOR="#111111" CREATED="1504519489525" ID="ID_680747202" MODIFIED="1504519502878" TEXT="&#x8be5;&#x533a;&#x57df;&#x4e0d;&#x53ef;&#x88ab;cache"/>
</node>
<node COLOR="#111111" CREATED="1504519238883" ID="ID_1055290886" MODIFIED="1504519475312" TEXT="&#x6bcf;&#x4e2a;CPU&#x6700;&#x597d;&#x91cd;&#x65b0;&#x5206;&#x914d;&#x4e00;&#x4e2a;&#x81ea;&#x5df1;&#x7684;4K&#x7a7a;&#x95f4;"/>
<node COLOR="#111111" CREATED="1504520321440" ID="ID_1658282363" MODIFIED="1504520327457" TEXT="&#x5bc4;&#x5b58;&#x5668;&#x5185;&#x5bb9;">
<node COLOR="#111111" CREATED="1504520362133" ID="ID_1523266607" MODIFIED="1504520380846" TEXT="&#x5bc4;&#x5b58;&#x5668;&#x6709;32&#x4f4d;&#x3001;64&#x4f4d;&#x3001;256&#x4f4d;&#x7684;"/>
<node COLOR="#111111" CREATED="1504520328247" ID="ID_1875304232" MODIFIED="1504520339569" TEXT="&#x6bcf;&#x4e2a;&#x5bc4;&#x5b58;&#x5668;16&#x5b57;&#x8282;(128-bit)&#x5bf9;&#x9f50;"/>
</node>
</node>
<node COLOR="#990000" CREATED="1504517849337" ID="ID_910752397" MODIFIED="1504517861184" TEXT="&#x53ef;&#x4ee5;&#x5173;&#x95ed;&#x5b83;&#xff0c;&#x7136;&#x540e;&#x76f4;&#x63a5;&#x4f7f;&#x7528;8259A">
<font NAME="SansSerif" SIZE="14"/>
</node>
</node>
<node COLOR="#00b439" CREATED="1504516233624" ID="ID_1219752532" MODIFIED="1504516239677" TEXT="I/O APIC">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
</node>
<node COLOR="#00b439" CREATED="1504517480542" ID="ID_1104191012" MODIFIED="1504517489083" TEXT="&#x4e2d;&#x65ad;&#x6765;&#x6e90;">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
<node COLOR="#990000" CREATED="1504517304557" ID="ID_594884440" MODIFIED="1504517553889" TEXT="&#x672c;&#x5730;&#x4e2d;&#x65ad;&#x6e90;">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504517557405" ID="ID_806455040" MODIFIED="1504517568527" TEXT="&#x672c;&#x5730;&#x7684;I/O&#x8bbe;&#x5907;">
<node COLOR="#111111" CREATED="1504517569423" ID="ID_1391337544" MODIFIED="1504517601762" TEXT="&#x76f4;&#x63a5;&#x8fde;&#x63a5;&#x5230;CPU&#x4e0a;LINT0&#x3001;LINT1&#x4e0a;&#x7684;&#x8bbe;&#x5907;&#x4e2d;&#x65ad;"/>
<node COLOR="#111111" CREATED="1504517602642" ID="ID_778639966" MODIFIED="1504517615332" TEXT="&#x4f8b;&#x5982;8259&#x4e2d;&#x65ad;&#x63a7;&#x5236;&#x5668;"/>
</node>
<node COLOR="#111111" CREATED="1504517213413" ID="ID_980013189" MODIFIED="1504517491675" TEXT="APIC&#x65f6;&#x949f;">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="12"/>
<node COLOR="#111111" CREATED="1504517242143" ID="ID_992315048" MODIFIED="1504517311066" TEXT="&#x5f53;&#x8fbe;&#x5230;&#x8bbe;&#x5b9a;&#x7684;&#x8ba1;&#x6570;&#x503c;&#x65f6;&#xff0c;&#x7ed9;&#x672c;&#x5730;CPU&#x53d1;&#x9001;&#x4e00;&#x4e2a;&#x4e2d;&#x65ad;">
<font NAME="SansSerif" SIZE="12"/>
</node>
</node>
<node COLOR="#111111" CREATED="1504517327784" ID="ID_736696100" MODIFIED="1504517517515" TEXT="&#x6027;&#x80fd;&#x76d1;&#x6d4b;&#x8ba1;&#x6570;&#x5668;">
<font NAME="SansSerif" SIZE="12"/>
<node COLOR="#111111" CREATED="1504517338514" ID="ID_552291546" MODIFIED="1504517361980" TEXT="&#x5f53;CPU&#x6027;&#x80fd;&#x76d1;&#x6d4b;&#x8ba1;&#x6570;&#x5668;&#x6ea2;&#x51fa;&#x65f6;&#xff0c;&#x53d1;&#x4e2a;&#x4e2d;&#x65ad;"/>
</node>
<node COLOR="#111111" CREATED="1504517375293" ID="ID_1402445601" MODIFIED="1504517523894" TEXT="&#x6e29;&#x5ea6;&#x4f20;&#x611f;&#x5668;">
<font NAME="SansSerif" SIZE="12"/>
<node COLOR="#111111" CREATED="1504517388160" ID="ID_664449939" MODIFIED="1504517401628" TEXT="&#x5f53;&#x6e29;&#x5ea6;&#x4f20;&#x611f;&#x5668;&#x8df3;&#x95f8;&#x65f6;&#xff0c;&#x53d1;&#x4e2a;&#x4e2d;&#x65ad;"/>
</node>
<node COLOR="#111111" CREATED="1504517404998" ID="ID_1711488793" MODIFIED="1504517530098" TEXT="APIC&#x5185;&#x90e8;&#x9519;&#x8bef;&#x63a2;&#x9488;">
<font NAME="SansSerif" SIZE="12"/>
<node COLOR="#111111" CREATED="1504517424039" ID="ID_1780599809" MODIFIED="1504517441533" TEXT="&#x8bc6;&#x522b;&#x5230;&#x5185;&#x90e8;&#x9519;&#x8bef;&#x65f6;&#xff0c;&#x53d1;&#x4e2a;&#x4e2d;&#x65ad;"/>
</node>
</node>
<node COLOR="#990000" CREATED="1504517636483" ID="ID_677535449" MODIFIED="1504517641391" TEXT="&#x5916;&#x90e8;&#x4e2d;&#x65ad;&#x6e90;">
<font NAME="SansSerif" SIZE="14"/>
</node>
<node COLOR="#990000" CREATED="1504516994778" ID="ID_1535014327" MODIFIED="1504517632130" TEXT="IPI(&#x591a;CPU&#x95f4;&#x901a;&#x4fe1;)">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="14"/>
<node COLOR="#111111" CREATED="1504517052680" ID="ID_1848090826" MODIFIED="1504517316301" TEXT="&#x901a;&#x8fc7;&#x7cfb;&#x7edf;&#x603b;&#x7ebf;&#xff0c;&#x5c06;&#x4e2d;&#x65ad;&#x4ece;&#x4e00;&#x4e2a;CPU&#x53d1;&#x9001;&#x5230;&#x53e6;&#x4e00;&#x4e2a;CPU">
<font NAME="SansSerif" SIZE="12"/>
</node>
<node COLOR="#111111" CREATED="1504517117323" ID="ID_1334796919" MODIFIED="1504517316302" TEXT="&#x4e3b;&#x8981;&#x7528;&#x9014;">
<font NAME="SansSerif" SIZE="12"/>
<node COLOR="#111111" CREATED="1504517162270" ID="ID_1477716024" MODIFIED="1504517166404" TEXT="&#x7cfb;&#x7edf;&#x81ea;&#x6211;&#x4e2d;&#x65ad;"/>
<node COLOR="#111111" CREATED="1504517166714" ID="ID_552920231" MODIFIED="1504517170500" TEXT="&#x4e2d;&#x65ad;&#x4e2d;&#x7ee7;"/>
<node COLOR="#111111" CREATED="1504517171109" ID="ID_994623872" MODIFIED="1504517192358" TEXT="&#x62a2;&#x5148;&#x65f6;&#x5e8f;&#x5b89;&#x6392;"/>
</node>
<node COLOR="#111111" CREATED="1504521835315" ID="ID_1369687130" MODIFIED="1504521850943" TEXT="&#x786c;&#x4ef6;&#x8bbe;&#x65bd;">
<node COLOR="#111111" CREATED="1504521851716" ID="ID_326802003" MODIFIED="1504521864395" TEXT="&#x4e2d;&#x65ad;&#x547d;&#x4ee4;&#x5bc4;&#x5b58;&#x5668;ICR">
<font BOLD="true" NAME="SansSerif" SIZE="12"/>
</node>
</node>
</node>
</node>
<node COLOR="#00b439" CREATED="1504517704354" ID="ID_867198921" MODIFIED="1504517711982" TEXT="&#x672c;&#x5730;&#x5411;&#x91cf;&#x8868;LVT">
<edge STYLE="bezier" WIDTH="thin"/>
<font NAME="SansSerif" SIZE="16"/>
</node>
</node>
</node>
</map>
