---
title: 一个记忆写入器怎样处理冲突
status: complete
date: 2026-07-03
---

# 一个记忆写入器怎样处理冲突

## 入口

本文沿着 MiniMem 的写入路径，说明一条用户事实怎样从消息变成可检索记录。分析基于 [源码快照](https://example.com/minimem/source) 与 [设计文档](https://example.com/minimem/design)。

![写入路径](https://example.com/images/write-path.png)

## 第一步：抽取候选事实

写入器把最近四轮消息交给抽取模型。模型返回候选事实和置信度：

```python
candidate = extractor.extract(messages[-4:])
if candidate.confidence < 0.72:
    return None
```

阈值阻止低置信候选进入存储，但它不能判断事实是否已经存在。

## 第二步：寻找冲突

系统用用户 ID 和事实类型做精确过滤，再在候选集合中做语义匹配。设计文档把相似度 0.86 以上的记录交给冲突分类器。

| 分类 | 动作 | 例子 |
|---|---|---|
| duplicate | 不写入 | “我住在上海”重复出现 |
| update | 关闭旧版本并写入新版本 | “我搬到杭州了” |
| coexist | 两条都保留 | “我喜欢茶”与“我也喝咖啡” |

## 第三步：写入版本链

更新不会覆盖旧行，而是先标记旧版本的 `valid_to`，再插入新行：

```sql
UPDATE memories SET valid_to = :now WHERE id = :old_id;
INSERT INTO memories (user_id, fact, valid_from) VALUES (:user, :fact, :now);
```

这让审计成为可能，也要求检索器默认排除已经关闭的版本。

## 失败路径：两个写入同时发生

源码先查询后写入，却没有把两步放在同一事务中。两个并发请求可能都读到旧版本，然后各自插入新版本，形成两个同时有效的事实。[并发问题](https://example.com/minimem/issues/42) 给出了复现步骤。

## 失败路径：删除没有传播

删除函数会写墓碑并从主索引移除向量，但不会主动清理已生成的上下文缓存。下一轮新检索不会返回记录，正在运行的 Agent 仍可能继续使用旧缓存。

## 次要问题：成本

每次写入最多调用一次抽取模型和一次冲突分类器。项目给出调用次数，没有给 token、延迟或并发冲突率。因此无法判断阈值 0.72 和 0.86 是否是成本最优选择。

## 边界

源码快照对应 0.4.1 版本。本文没有运行生产负载，也没有验证数据库隔离级别变化后的表现。

## 结论

MiniMem 的关键不在向量检索，而在版本链如何表达事实变化。当前实现能保留历史，但并发写入和缓存删除仍需要额外协议。
