---
description: Declare this session's version date, so the session title is prefixed V<date>｜ instead of T<date>｜
argument-hint: "[YYYYMMDD] [prompts]"
---

本次会话的版本号是下面这行开头的 8 位日期，由会话重命名器读取，你不必为它做任何事。
正常处理日期后面的请求即可，回答里不要提这个版本号；只有当日期后没有任何内容时，才回一句「已记录版本 <日期>」。

版本 $ARGUMENTS
