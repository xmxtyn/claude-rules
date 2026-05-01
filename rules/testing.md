# 测试策略（务实原则）

**核心思想**：测试应该顺手写，不要想着"以后再补"。

## 测试分层

| 测试类型 | 投入成本 | 适用场景 |
|---------|---------|---------|
| 冒烟测试 | 低（手动跑核心 API） | 每次部署后 |
| 单元测试 | 中 | 复杂校验规则、计算逻辑 |
| API 集成测试 | 中（httptest） | 关键业务路径 |
| E2E 自动化 | 高 | 核心用户流程，确有必要时做 |

## 必须有的测试

1. **核心业务单元测试**：复杂校验规则、计算逻辑
2. **部署后冒烟测试**：curl 测试核心 API
3. **API 集成测试**：使用 httptest，不依赖真实 DB

## 禁止行为

- ❌ 不写测试就说"以后再补"
- ❌ 为了覆盖率测简单 getter/setter
- ❌ 用 mock 测你已经集成了真实 DB 的 Repository 层
- ❌ Mock 你已经集成了真实 DB 的 Repository 层

## Go 集成测试示例

```go
// 使用 httptest 做 API 测试
func TestDeviceHandler_Create(t *testing.T) {
    // 使用内存数据库或 mock
    router := gin.New()
    handler := NewDeviceHandler(mockService)
    router.POST("/devices", handler.Create)

    req := httptest.NewRequest("POST", "/devices", bytes.NewBuffer(jsonData))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    router.ServeHTTP(w, req)

    if w.Code != http.StatusCreated {
        t.Errorf("expected status 201, got %d", w.Code)
    }
}
```

## 何时增加测试

当你写完一个新功能后，**顺手**写测试：
1. 功能完成后，花 5-10 分钟写核心路径测试
2. 发现 bug 时，先写能复现 bug 的测试再修复
3. 重构前，写测试保护关键逻辑
