# 1. 入门情景

## 1.1. 单机解决

- 情景 1：
  - 情景：
    ```
    1T文本文件，每行一个数据
    128MB内存计算机
    求重复行
    ```
  - 解决 1：
    - 方式：
      ```
      每次读取一行
      对一行的数据求hash值
      将hash为文件名，一行数据为文件内容，存入磁盘
      每行对应一个文件（n:1，重复行hash值也相同）
      遍历所有文件，查行数大于1的文件
      ```
    - 问题
      - 单服务器问题：
        - 单点瓶颈：一个计算机性能有限
        - 单点故障：一个服务器出故障后整个服务瘫痪
      - 文件过多，遍历压力大
  - 解决 2：
    > **hash 稳定算法**
    - 方式；
      ```
      每次读一行
      求hash值，再膜10000
      将hash%10000相同的数据存放到一个文件中（相当于初步分组，将文件数量控制在10000）
      （hash稳定算法，控制文件数量同时达到负载均衡的效果，hadoop和redis中都有相关扩展和应用）
      ```
    - 问题；
- 情景 2
  - 情景：
    ```
    1T文本数据
    128MB计算机
    每行一个数字
    对文件进行全排序
    ```
  - 解决 1：单文件无序，文件间有序
    ```
    划分多个文件存储范围，（0-100，,101-200，201-300....）
    将1T数据分别存到多个文件中
    对每个文件中的数据进行排序
    按顺序合并多个文件
    ```
  - 解决 2：单文件有序，文件间无序
    ```
    每次从1T数据中拿出一定量数据（小于128MB）进行排序，存到一个文件中
    最终把1T分割成多个有序的小文件
    使用归并算法，将小文件合并为一个有序的大文件
      0. 新建空白结果文件
      1. 每个文件中取第一个（最小的数据），放到内存中
      2. 将内存中最小的数(假设来自文件a)追加到结果文件
      3. 将文件a中最小的数补充到内存中
      4. 重复1-3
    ```

## 1.2. 分布式解决(cluster)

- 情景 1

  - 情景：
    ```
    1T文本文件，每行一个数据
    2000个服务器128MB内存
    求重复行
    ```
  - 解决 1：
    - 方式；
      ```
      每个服务器分500MB文件
      每个服务器
        每行求hash再膜2000，以此为文件名
        生成2000个文件
      从每台服务器中取文件名相同的文件 比如1，放到额外一台更高内存服务器上
      再查找相同行
      ```
    - 问题：
      - 1T 数据切割分发给 2000 台服务器
        ```
        分到2000台服务器，一台服务器分500MB数据
        向一个服务器发送500MB需要5s，则2000台服务器需要10000s（两个半小时）
        ```
      - 数据迁移，同名文件迁移到同一个服务器花费时间
        ```
        千兆网卡处理速度为百兆级
        假设文件均匀分布，所有文件名为1的总和大小为500MB
        并且通过算法解决了io冲撞问题，并满速传输
        那么传输到一台服务器需要5s
        ```

- 实际情景：

  ```
  假设每天有1T数据
  每天都会花费一定时间进行数据的分发
  每台服务器每次增加较少数据量
  每台服务器并行执行，计算耗费时间可控
  ```

- 分布式集群：
  > 分而治之，并行计算
  - 并行：提升速度的关键
  - 分布式执行
  - 计算与数据一起
  - 文件切割的规范管理
    > 数据切割后存放管理策略
  - 存+计算
    - 计算向数据移动
      ```
      hadoop精华所在
      数据量非常大，迁移耗费时间大
      所以把计算程序向程序移动
      ```
  - 应用
    - Net music log 播放次数，标签等
    - 有线电视日志统计,点击率，换台时机，计算观看率等

# 2. hadoop

## 2.1. 简介

- 思想之源：Google（第一个遇到大数据问题的公司）
- 面对数据和计算难题：
  - 大量网页怎么存储
  - 搜索算法
- Google 三大理论

  - GFS：分布式文件系统
  - Map-Reduce:分布式计算框架
  - Bigtable

- Doug cutting 看完 google 论文后，在 Yahoo 就职期间开发的 hadoop 框架

- hadoop 底层基于倒排索引

  - 倒排索引：即 luence 框架
    > 苹果动态搜索引擎就基于 luence 框架
    > 之后会学

- 历程：
  ```
  Hadoop简介
  名字来源于Doug Cutting儿子的玩具大象。
  2003-2004年，Google公开了部分GFS和Mapreduce思想的细节，以此为基础Doug Cutting等人用了2年业余时间实现了DFS和Mapreduce机制，一个微缩版的Nutch(nutch:第一个开源的分布式搜索框架，apache公司)
  Hadoop 于 2005 年秋天作为 Lucene的子项目 Nutch的一部分正式引入Apache基金会。2006 年 3 月份，Map-Reduce 和 Nutch Distributed File System (NDFS) 分别被纳入称为 Hadoop 的项目
  ```
- Hadoop 简介：https://hadoop.apache.org/old/
  - 版本：1.x，2.x，3.x
  - 组成：
    - 大数据工具包：Hadoop Commom
    - 分布式存储系统 HDFS （Hadoop Distributed File System ）POSIX
      - 分布式存储系统
      - 对数据文件切割并进行分发
      - 提供了 高可靠性、高扩展性和高吞吐率的数据存储服务
    - 分布式资源管理框架 YARN（Yet Another Resource Management）
      - 负责集群资源的管理和调度
    - 分布式计算框架 MapReduce
      - 分布式计算框架（计算向数据移动）
      - 具有 易于编程、高容错性和高扩展性等优点。
  - 衍生（生态环境圈）：
    ![](./image/hadoop-begin-1.jpg)

## 2.2. 分布式文件系统 HDFS

> 就是一个文件系统，操作类似linux

### 2.2.1. 存储模型

> 就是上面的完整数据进行切割

- 存储模型：字节
  - 文件线性切割成块（Block）:偏移量 offset
    - Block:切成的块
    - offset：偏移量，起始位置。用于索引定位
    - 中文处理：切割时不管，后期会进行处理
  - Block 分散存储在集群节点中
    > 尽量均衡分配
  - 单一文件 Block 大小一致，文件与文件可以不一致
    > 除最后一个块大小相同
  - Block 可以设置副本数，副本无序分散在不同节点中
    > 切出的块进行复制，散布在不同节点上，是为了数据安全
    - 副本数不要超过节点数量，没有意义
  - 文件上传可以设置 Block 大小和副本数（资源不够开辟的进程）
    - Block 大小默认 128MB，最小 1MB。可以自行设置
    - 副本数默认 3 个。可以自行设置
      > 比如有多个进程需要读取数据块，可以把副本数设置多些，将进程分散到不同服务器，避免造成拥堵现象
  - 已上传的文件 Block 副本数可以调整，**大小不变**
  - 只支持一次写入多次读取，同一时刻只有一个写入者
  - 可以 append 追加数据
    > 把数据添加到最后一块,或者追加数据作为最后一块。

### 2.2.2. 架构模型

> 通过一定的有序的组织架构，让架构运行起来并对数据进行健康完美的维护的模型

- 1.0 版本架构模型：主从架构模型
  > 一个主节点，管理多个从节点
  - 数据种类：
    - 元数据 MetaData
      - 文件权限
      - 每个块的块大小
      - 每个块的块偏移量
      - ......（持久化那里有）
    - 块数据本身，文件数据
  - 分工：
    - 主节点(NameNode)：保存和维护文件元数据：单节点 posix
    - 从节点(DataNode)：保存和处理文件 Block 数据：多节点
  - 主从交互
    - DataNode 与 NameNode 保持心跳，提交 Block 列表
      > DataNode 向 NameNode 主动提交 Block 列表
  - 客户端，CS 架构
    - HdfsClient 与 NameNode 交互元数据信息
    - HdfsClient 与 NameNode 交互获得指定块的位置，再直接与 DataNode 交互文件 Block 数据
  - 存储：
    - DataNode 利用服务器本地文件系统存储数据块

### 2.2.3. 架构模型

![](./image/hadoop-begin-2.jpg)

- HdfsClient 能与 DataNote 直接交互，这里没画出来
- Secondary NameNode:1.0 版本中比较重要。2.0 及之后就用不到了

![](./image/hadoop-begin-3.jpg)

### 2.2.4. 节点类型与版本1.0持久化

- NameNode（NN）
  - **基于内存存储** ：不会和磁盘发生交换（双向）
    > 与redis等内存数据库相同
    - 只存在内存中，进行计算
    - 定期做持久化（单向）
      > 只会把内存中的数据写到磁盘备份<br>
      > 只有恢复数据时才读取数据
  - NameNode主要功能：
    - 接受客户端的读写服务
    - 收集DataNode汇报的Block列表信息
  - NameNode保存metadata信息包括
    - 文件持有者(owership)和(permissions)
    - 文件大小，时间
    - Block信息（Block列表，Block偏移量，Block副本位置）（**持久化不存**）
      > 由DataNode主动将块数据的信息汇报给NameNode，确保DataNode的存活，不用存储

- DataNode（DN）
  - 本地磁盘目录存储数据（Block），文件形式
  - 同时存储Block的元数据信息文件(MD5文件,(MD5加密))
    > 该元数据信息对应Block
  - 启动DN时会向NN汇报block信息
  - 通过向NN发送心跳保持与其联系（3秒一次），如果NN 10分钟没有收到DN的心跳，则认为其已经lost，并copy其上的block到其它DN
    > 之后会自动从其他节点上查找副本数据恢复节点数据<br>
    > 另外因为数据量大，判断lost的间隔不能太小，否则数据转移对服务器压力太大，期间也可能修复，10分钟差不多。

- NameNode持久化
  - 方式：
    - metadata存储到磁盘文件名为”fsimage”（时点备份）
      - fsimage:镜像快照
      - 是实现java序列化接口的对象序列化后的文件
      - 序列化写入磁盘慢，但恢复时快，因为就是二进制文件，直接读入内存即可
    - edits记录对metadata的操作日志-->Redis
      - edits log
      - 会把客户端对NameNode的所有操作写到操作日志中
      - 写入块，但恢复很慢，因为要一条一条执行
    - 实际会两者混用
      - 最开始启动时，hadoop会格式化(format)，生成空白fsimage和edits
      - 进行操作时，会把操作记录存储到edits中，不会修改fsimage
      - 每次当edits到达一定条件时(比如文件大小)，会触发fsimage合并工作
        - 以fsimage为基础，读取edits中的内容进行合并
        - fsimage更新后，edits会被清空
        - 而做合并工作的，就是 **SecondNameNode(SNN)**
  - 特点：
    - NameNode的metadata信息在启动后会加载到内存
    - Block的位置信息不会保存到fsimage

- SecondNameNode
  - 它不是NN的备份（但可以做备份），它的主要工作是帮助NN合并edits log，减少NN启动时间。
  - SNN执行合并时机
    - 根据配置文件设置的时间间隔fs.checkpoint.period  默认3600秒
    - 根据配置文件设置edits log大小 fs.checkpoint.size 规定edits文件的最大值默认是64MB	
  - 合并流程:
    > ![](./image/hadoop-begin-4.jpg)
  - 恢复流程：
    - 读取fsimage
    - 如果edits文件不为空，就读取并执行
  - 2.x之后有了NameNode备份，SecondeNameNode基本没用了
    - 之后会讲持久化工作的替代者

### 2.2.5. 优缺点

- HDFS优点：
  - 高容错性
    > block management policy 副本管理策略
    - 数据自动保存多个副本
    - 副本丢失后，自动恢复
  - 适合批处理
    - **移动计算而非数据**
    - 数据位置暴露给计算框架（Block偏移量）
  - 适合大数据处理
    - GB 、TB 、甚至PB 级数据
    - 百万规模以上的文件数量
  - 可构建在廉价机器上
    - 通过多副本提高可靠性
    - 提供了容错和恢复 机制
- HDFS缺点：
  - 做不到低延迟数据访问,比如毫秒级
    > 因为数据量很大，基本上是分钟级别的。
    - 高吞吐率，要求块大小不能小于1MB
  - 小文件存取效率底下
    - 占用NameNode 大量内存
      > 比如10亿个小文件，需要维护的元数据信息量非常大
    - 寻道时间超过读取时间
      > 寻找10亿个文件耗时多，所以尽量使文件大些，文件少些，减少寻道时间
  - 并发写入、文件随机修改
    - 一个文件只能有一个写者
    - 仅支持append

### 2.2.6. 副本放置策略

- 服务器类型：
  - 塔式服务器，类似家用计算机主机
  - 机架服务器，扁平，放在架子上
    > 用得多
  - 刀片服务器，

- 组网模式：
  - 老式：
    > ![](./image/hadoop-begin-6.jpg)
  - 平面组网
    > ![](./image/hadoop-begin-7.jpg)

- Block的副本放置策略
  > 不同服务器策略和组网模式方式策略不同
  > hadoop-hdfs-2.6.5.jar--org.apache.hadoop.hdfs.blockmanagement--BlockPlacePolicyDefault 类中注释有副本方式策略
  - 机架服务器
    - 第一个副本：放置在上传文件的DN；如果是集群外提交，则随机挑选一台磁盘不太满，CPU不太忙的节点。
    - 第二个副本：放置在于第一个副本不同的 机架的节点上。
    - 第三个副本：与第二个副本相同机架的节点。
    - 更多副本：随机节点

![](./image/hadoop-begin-5.jpg)
  > rack 机架

### 2.2.7. 核心流程


- 写流程(动作执行者为client)：
  > ![](./image/hadoop-begin-8.jpg)
  > DistributedFileSystem， FSDataOutputStream为两个对象，后者由前者创建，之后用的时候会更了解，此处不多讲<br>
  >  FSDataOutputStream只会向第一个副本节点传输数据<br>
  > FSDDataOutputStream和DataNode之间可以看作管道，流式传输，FSDDataOutputStream发送的数据包会流过三个DataNode<br>
  > 确认只发生在Client和第一个DataNode之间。所有DataNode一直和NameNode一直保持着通信，所以不必担心无法获知block是否传输完整<br>
  > 时间重叠：第一个DataNode传完之后，会立即启动下一个block的传输，但此时第二和第三个DataNode依旧在接收数据
  - 选择文件
  - 切分文件Block
  - 按Block线性和NN获取DN列表（副本数）
  - 验证DN列表后以更小的单位流式传输数据
    - 各节点，两两通信确定可用
  - Block传输结束后：
    - DN向NN汇报Block信息
    - DN向Client汇报完成
    - Client向NN汇报完成
  - 获取下一个Block存放的DN列表
  - 。。。。。。
  - 最终Client汇报完成
  - NN会在写流程更新文件状态

- 读流程(动作执行者为client)：
  > ![](./image/hadoop-begin-9.jpg)
  > 本地读取策略：就近原则多个副本时，会读取最近的空闲的服务器
  - 和NN获取一部分Block副本位置列表
  - 线性和DN获取Block，最终合并为一个文件
  - 在Block副本列表中按距离择优选取
  - MD5验证数据完整性

### 2.2.8. HDFS其他

- 文件权限
  - HDFS文件权限:POSIX标准（可移植操作系统接口）
    - POSIX:Portable Operating System Interface
    - 与Linux文件权限类似
      - r: read; w:write; x:execute
      - 权限x对于文件忽略，对于文件夹表示是否允许访问其内容
    - 如果Linux系统用户zhangsan使用hadoop命令创建一个文件，那么这个文件在HDFS中owner就是zhangsan。
    - HDFS的权限目的：阻止误操作，但不绝对。HDFS相信，你告诉我你是谁，我就认为你是谁。

- 安全模式；
  - namenode启动的时候，首先将映像文件(fsimage)载入内存，并执行编辑日志(edits)中的各项操作。
  - 一旦在内存中成功建立文件系统元数据的映射，则创建一个新的fsimage文件(这个操作不需要SecondaryNameNode)和一个空的编辑日志。
  - 此刻namenode运行在安全模式。即namenode的文件系统对于客服端来说是只读的。(显示目录，显示文件内容等。写、删除、重命名都会失败，尚未获取动态信息)。
  - 在此阶段Namenode收集各个datanode的报告，当数据块达到最小副本数以上时，会被认为是“安全”的， 在一定比例（可设置）的数据块被确定为“安全”后，再过若干时间，安全模式结束
  - 当检测到副本数不足的数据块时，该块会被复制直到达到最小副本数，系统中数据块的位置并不是由namenode维护的，而是以块列表形式存储在datanode中。

- 角色==进程
  - namenode
    - 数据元数据
    - 内存存储，不会有磁盘交换
    - 持久化（fsimage，edits log）
      - 不会持久化block的位置信息
    - block：偏移量，因为block不可以调整大小，hdfs，不支持修改文件
      - 偏移量不会改变
  - datanode
    - block块数据，块元数据信息
    - 磁盘
    - 面向文件，大小一样，不能调整
    - 副本数，可调整，（备份，高可用，容错/可以调整很多个，为了计算向数据移动）
  - SN(2.x版本中就没了)
  - NN&DN
    - 心跳机制
    - DN向NN汇报block信息
    - 安全模式
  - client

### 2.2.9. 根据官网部署伪分布式

> 具体请查看搭建文档 ![](./hadoop搭建文档.txt)

- 可以有三种模式进行部署：
  - Local (Standalone) Mode：本地多线程方式模拟hadoop运作，测试时用用，一般不用
  - Pseudo-Distributed Mode：伪分布式。主从节点放到一个机器上
  - Fully-Distributed Mode：全分布式。

- 伪分布式：
  - 设置ssh免密码登录
    - ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
    - cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
    - scp ./authorized_keys ......
  - 安装jdk，设置环境变量
  - 二次修改环境变量。vi /opt/learn/hadoop-2.6.5/etc/hadoop-env.sh
    > 因为其他服务器上不一定修改了profile，干脆在hadoop配置文件中修改得了
    ```sh
    export JAVA_HOME=${JAVA_HOME}
    # 改为
    export JAVA_HOME=/usr/java/jdk1.7.0_67
    ```
    - 顺便把所有块mapred-env.sh,yarn-env.sh也都改了
  - 根据官方修改
    - core-site.xml：主节点配置信息
      > Localhost改成node0001
    - hdfs-site.xml：副本数量。伪分布式部署，默认为1
  - 设置DataNode ：slaves文件
    > 改为node0001
  - 进入hdfs-sit.xml配置SecondNameNode
    > 查看默认配置：
    > ![](./image/hadoop-begin-10.jpg)
    ```xml
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>node0001:50090</value>
    </property>
    ```
  - 修改core-site.xml
    > 同样方式查找默认配置
    - hdfs中将元数据信息保存到，同时块数据也在该路径下
      > ![](./image/hadoop-begin-11.jpg)
      > ![](./image/hadoop-begin-12.jpg)
    - hadoop.tmp.dir在core-site.xml中设置，默认`/tmp/hadoop-${user.name}`
    - 如果默认的话，一清楚tmp文件就玩完
    - 所以要修改下
      ```xml
      <configuration>
          <property>
              <name>fs.defaultFS</name>
              <value>hdfs://node0001:9000</value>
          </property>
          <property>
              <name>hadoop.tmp.dir</name>
              <value>/var/learn/hadoop/pseudo</value>
          </property>
      </configuration>
      ```
  - 格式化NameNode
    > DataNode,SecondNameNode在启动时会生成相关文件，格式化只针对NameNode<br>
    > edits文件启动后生成
  - 查看/var/learn/hadoop/pseudo下的文件
    - name文件夹：namenode元数据信息
      - current
        - fsimage_0000000000000000000  
        - fsimage_0000000000000000000.md5 
        - seen_txid :集群唯一标识号，format阶段形成，给所有角色共享
          > 格式化一次就会变一次，但其他角色id不会变。所以不要多次启动
          > 解决方式：
        - VERSION
  - 启动
    > ![](./image/hadoop-begin-13.jpg)
    > ![](./image/hadoop-begin-14.jpg)
  - 可以在浏览器进入`192.168.187.101:50070`查看负载情况
    - Live Nodes指的是DataNode节点
  - NameNode创建路径，再上传文件
    - hdfs dfs 可以查看所有文件管理命令，贴近于linux
    - hdfs dfs -mkdir -p /user/root
      > 上传文件的默认路径
    - hdfs dfs -ls 查看所有文件夹
  - 上传文件
    - hdfs dfs -put ~/files/hadoop-2.6.5.tar.gz /user/root
    - copying状态不可访问
      > ![](./image/hadoop-begin-15.jpg)
    - 上传完后，可以查看block（默认128MB，所以就是两块）
      > ![](./image/hadoop-begin-16.jpg)
    - 快文件存储在/var/learn/hadoop/data下
      > ![](./image/hadoop-begin-17.jpg)
  - 关闭：stop-dfs.sh
    



## 2.3. 分布式计算框架 MR

> 计算向数据移动

## 2.4. 体系结构

## 2.5. 安装

## 2.6. shell

## 2.7. API
