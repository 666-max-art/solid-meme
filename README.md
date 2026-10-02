# C++ 初学者小项目清单

整理日期：2026-10-02

这份清单收集了 6 个适合从基础语法逐步练到容器、类和文件读写的控制台项目，附原始源码链接和独立实现的练习步骤。推荐先按需求自己写一版，再阅读参考源码，最后增加一个新功能。

## 选择与练习顺序

以下难度是根据已阅读源码作出的学习建议。所选程序使用 C++ 标准库，无需额外安装 GUI、数据库或网络库；其中计算器需要编译两个源文件。

| 顺序 | 项目 | 建议难度 | 主要练习 | 参考源码 |
| --- | --- | --- | --- | --- |
| 1 | 猜数字游戏 | 入门 | 输入输出、条件分支、循环、函数、随机数 | [main.cpp](https://github.com/Mmabiaa/Cpp-Beginner-Projects/blob/main/Number%20Guessing%20Game/main.cpp) |
| 2 | 温度转换器 | 入门 | 浮点数、公式、字符处理、函数拆分 | [main.cpp](https://github.com/Anshu-Gondi/CPP-Projects-Beginner-to-Intermediate/blob/main/Beginner%20Projects/Temperature%20Convertor/main.cpp) |
| 3 | 四则运算计算器 | 入门 → 基础进阶 | switch、输入校验、类、头文件、多文件编译 | [项目目录](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/tree/main/Src/Simple_Calculator) |
| 4 | 待办清单 | 基础进阶 | string、vector、类、增删改查 | [todo.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/To-Do-List/todo.cpp) |
| 5 | 成绩与学分统计 | 基础进阶 | 对象集合、加权平均、格式化输出 | [main.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Semester_Grade_Calculator/main.cpp) |
| 6 | 简易记账本 | 基础进阶 | vector、类、文件读写、查找与汇总 | [main.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Expense_Tracker/main.cpp) |

## 1. 猜数字游戏

**做什么：** 生成一个 1–100 的整数，让玩家不断猜测，并提示偏大、偏小或猜中。

**练习步骤：**

1. 先固定答案，完成输入、比较和重复猜测。
2. 加入随机答案、猜测次数统计，以及重新开始的选项。
3. 处理非数字输入和范围之外的数字，再增加次数限制或难度等级。

**完成标准：** 固定答案为 42 时，输入 20 提示偏小，输入 60 提示偏大，输入 42 结束本轮；输入字母后仍能继续操作。

**阅读提示：** 参考实现使用 `rand()` 和 `srand()`，尚未校验数字输入。第二版可尝试用 `<random>` 生成随机数。

来源：[Mmabiaa/Cpp-Beginner-Projects](https://github.com/Mmabiaa/Cpp-Beginner-Projects)。

## 2. 温度转换器

**做什么：** 在摄氏度 C、华氏度 F 和开尔文 K 之间转换。

**练习步骤：**

1. 先实现 C 与 F 互转，注意使用浮点运算。
2. 增加 K，并拆成“转为摄氏度”和“由摄氏度转出”两个函数。
3. 加入大小写兼容、循环菜单、非数字输入处理，以及绝对零度校验。

**完成标准：** 0 C → 32 F，100 C → 212 F，273.15 K → 0 C；输入无效单位时给出提示，低于绝对零度时拒绝转换。

**阅读提示：** 参考实现已有单位校验与重复转换，数字输入失败和绝对零度检查适合作为补充练习。

来源：[Anshu-Gondi/CPP-Projects-Beginner-to-Intermediate](https://github.com/Anshu-Gondi/CPP-Projects-Beginner-to-Intermediate)。

## 3. 四则运算计算器

**做什么：** 输入运算符与两个数，计算加、减、乘、除，并支持退出。

**练习步骤：**

1. 用 `switch` 实现四种运算，先写成一个源文件。
2. 处理除数为零、无效运算符和非数字输入。
3. 将计算逻辑移入 `Calculator` 类，拆分头文件与实现文件，再增加历史记录。

**完成标准：** 2 + 3 得到 5，7 / 2 得到 3.5，5 / 0 给出错误提示；错误输入不会导致菜单失效。

**阅读提示：** 参考实现已经通过异常处理除零，但无效数字输入会退出程序。可改为提示后重试。

来源：[main.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Simple_Calculator/main.cpp)、[Calculator.h](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Simple_Calculator/Calculator.h)、[Calculator.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Simple_Calculator/Calculator.cpp)。

## 4. 待办清单

**做什么：** 添加任务、查看列表、标记完成和删除任务。

**练习步骤：**

1. 用 `vector<string>` 完成添加与展示。
2. 改用任务类或结构体保存标题与完成状态，实现标记、删除和编号校验。
3. 增加修改标题、筛选未完成任务，再用文件保存任务。

**完成标准：** 添加两项任务后能分别标记和删除；空标题、无效编号和空列表都有合理反馈；扩展保存功能后，重启仍能恢复任务。

**阅读提示：** 参考实现使用 `Task` 与 `ToDoList` 两个类，已检查空标题和任务编号；任务只存在内存中，文件保存是新增练习。

来源：[todo.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/To-Do-List/todo.cpp)。

## 5. 成绩与学分统计

**做什么：** 输入课程、成绩和学分，输出课程列表与加权统计。

**练习步骤：**

1. 保存多门课程，计算最高分、最低分和普通平均分。
2. 按学分计算加权平均，输出整齐的课程表。
3. 自定义绩点规则，补齐课程数、成绩、学分和非数字输入的校验。

**完成标准：** 80 分、2 学分与 90 分、3 学分的加权平均为 86 分；没有课程或总学分为零时避免除零。

**阅读提示：** 参考实现计算的是学分加权 GPA，并内置两套绩点映射。练习时按自己的课程要求定义规则；源码仍需补强正学分和数字输入校验。上面的 86 分是建议新增的加权平均成绩功能。

来源：[main.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Semester_Grade_Calculator/main.cpp)。

## 6. 简易记账本

**做什么：** 记录类别、金额和备注，支持查看、汇总、按类别查找、删除，以及保存到文件。

**练习步骤：**

1. 在内存中实现记录的添加、查看和删除。
2. 使用文本文件加载和保存记录，验证重启后数据是否保留。
3. 增加分类汇总、金额与输入校验，并处理格式错误的文件内容。

**完成标准：** 添加 12.50 和 7.50 两笔支出后合计为 20.00；删除第一笔后合计为 7.50；重启后记录一致，错误文件不会让程序直接退出。

**阅读提示：** 参考实现保存到当前工作目录的 `expenses.txt`，已有基础持久化。金额解析、文件写入失败和输入中的逗号仍可补强；处理金额时也可尝试用整数“分”存储。

来源：[main.cpp](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects/blob/main/Src/Expense_Tracker/main.cpp)。

## 如何开始

先会变量、`cin/cout`、`if/switch`、循环和函数即可开始前两项。练到第 4 项时再学习 `string`、`vector` 和类；第 6 项再学习 `fstream`。

以下是根据已核对文件路径整理的 Windows PowerShell + g++ 示例，需要先安装并配置 g++。命令尚未在本机编译验证。

### 先运行猜数字参考项目

```powershell
git clone https://github.com/Mmabiaa/Cpp-Beginner-Projects.git
cd "Cpp-Beginner-Projects/Number Guessing Game"
g++ -std=c++17 -Wall -Wextra main.cpp -o guess.exe
.\guess.exe
```

### 再练习多文件计算器

在另一个目录或终端中：

```powershell
git clone https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects.git
cd "CPP_Mini_Projects/Src/Simple_Calculator"
g++ -std=c++17 -Wall -Wextra main.cpp Calculator.cpp -o calculator.exe
.\calculator.exe
```

部分源码使用 emoji，显示效果取决于终端编码与字体；自己的版本可以使用普通文字提示。

建议在本仓库的 `projects/` 下为自己的每个练习建立独立目录，并在项目 README 中记录功能、编译命令、测试输入和下一步改进。

## 来源与核验范围

- [Mmabiaa/Cpp-Beginner-Projects](https://github.com/Mmabiaa/Cpp-Beginner-Projects)：猜数字。
- [Anshu-Gondi/CPP-Projects-Beginner-to-Intermediate](https://github.com/Anshu-Gondi/CPP-Projects-Beginner-to-Intermediate)：温度转换。
- [OPCODE-Open-Spring-Fest/CPP_Mini_Projects](https://github.com/OPCODE-Open-Spring-Fest/CPP_Mini_Projects)：计算器、待办、成绩统计、记账。

已核对以上六项的源码路径并阅读相关源码；推荐难度、练习步骤和完成标准为本清单编写的学习建议。原项目可能继续更新。本仓库目前保存项目链接和学习说明，源码可从上述链接查看。
