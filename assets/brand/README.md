# MeloUnion 品牌资产

本目录中的 `svg/` 是正式矢量源文件，`png/` 是常用尺寸导出。PNG 均由对应 SVG 导出；正式设计修改应先更新 SVG，再重新导出 PNG。

## 配色

- Melo Teal：`#0AA69A`
- Melo Dark：`#1C2736`
- White：`#FFFFFF`

## 使用建议

- 浅色背景：使用 `*-positive`。
- 深色或品牌色背景：使用 `*-reverse`；反向 SVG/PNG 为白色透明底。
- 单色印刷：使用 `logo-horizontal-mono-navy`。
- 应用图标、头像和 favicon：使用 `mark-positive`。
- 不要拉伸、旋转、添加阴影或改变图标与文字的相对间距。

## 重新导出

```bash
node assets/brand/generate-brand-assets.mjs
```
