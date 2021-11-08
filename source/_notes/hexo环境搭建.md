---
title: hexo环境搭建
date: 2021-10-24 12:58:26
tags: 
---

摘要：搭建hexo博客的大致步骤

<!--more -->

# HEXO 主题制作

[hexo](https://hexo.io/zh-cn/docs/index.html) 是一个快速、简洁且高效的博客框架。Hexo 使用 Markdown（或其他渲染引擎）解析文章，在几秒内，即可利用靓丽的主题生成静态网页。  
推荐一位博主的[教程](https://www.cnblogs.com/yyhh/p/11058985.html)。

- [x] 了解 hexo 主题制作方法 
- [x] 研究当前的主题所用框架
- [x] 学习开发相关知识
- [x] 调整布局，效果等

#### 一、 学习相关知识

默认主题已经挺不错了，直接在它基础上修改。

* [hexo](https://hexo.io/zh-cn/docs/themes) 官方文档。  
    hexo 可以主题定义的样式等，自动将markdown转成静态网页。
* `ejs`+`stylus` 相关知识  
    默认主题用的是[ejs](https://ejs.bootcss.com/) +[stylus](https://stylus.bootcss.com/)。都不会，没办法，学！

#### 二、 主题结构

默认主题的结构还是很简单的，在`layout`目录下的`.ejs`文件定义了页面的布局。在`source/css`目录下同名的`.styl`定义了各个样式，只要按照自己的想法，自由修改即可。

如果~~一窍不通~~不想太过深入于框架，只想关注于快速修改成心目中的模样，可以如我一般采用以下方法：
用谷歌浏览器查看页面源码，选择想要修改的部分，记住它的名字，从项目中查找这部分并进行自由调整。

**注意：**
* 尽量使用常量表`_variables.styl`，避免内容中的hardcode，不然调整起来超痛苦。
* 需要关注在手机端的效果。

#### 三、 主题润色

经过修改后的个人博客成为了这个样子[Wenzhou's Blog](https://wz2671.github.io/)。

主要做了以下修改：

1. 将整页背景替换为一个图片，并不随背景滚动。  
    做法：将`css/style.styl`中`#wrap`下的`background`修改为背景图片的`url`即可，后面还要注明`fixed`，除此，还要注意将`height`注释掉，不然向下翻页时依旧是显示白色背景。
    ```stylus
    #wrap
    // height: 50%  // 未填满部分会留白
    width: 100%
    position: absolute
    top: 0
    left: 0
    transition: 0.2s ease-out
    z-index: 1
    // background: color-background
    background: url(banner-url) fixed 
    background-size: cover 
    background-position: center     // 可以使图片一直居中
    .mobile-nav-on &
        left: mobile-nav-width
    ```
2. 将`header`（标题那一块）和`footer`（页脚）那一块改为了透明，并加了一点点无聊的模糊效果。  
    做法：非常简单，定位到`_partial/header.styl`中`#header`和`_partial/footer.styl`中`#footer`把背景色去掉即可，模糊效果使用`filter: blur(8px)`即可。
3. 将`main`（中间正文部分）的横向限制去除。  
    做法：将`style.styl`中`.outer`的`max-width`条目删除即可。
4. 修改了各个部分的配色，包括`main`的背景、`page-nav`背景，`widget`背景以及相应的字体颜色，微调各个部分布局。  
    如果不用大改布局的话，依旧只要调调`css`目录下的样式，so easy。
5. 修改代码块的配色及布局，表格边框配色和布局，引用的字体大小及间距，列表的间距等。  
    代码高亮部分在`_partial/highlight.styl`中。表格的样式在`_partial/article.styl`中`.article-entry`的`table`、`th`、`td`中。按照自己想要的效果简单修改即可。引用的样式在同样在该文件的`blockquote`下定义的。
6. 添加了对时序图、流程图`mermaid`的支持。  
    对流程图的支持可参考gayhub上的[仓库](https://github.com/webappdevelp/hexo-filter-mermaid-diagrams)，readme里有较为清晰完整的指引。
7. 一个神秘问题，在主题配置文件`_config.yml`中将`lang`修改为任意语言后，会在一些奇怪地方显示德语，例如`share`、`next`文字之处，出现原因还未知，目前采用的解决方法是把`theme/languages`下的`de.yml`删了（谁TM想看德语？），以后若有兴趣，再来研究该问题出现的具体原因。

装修完成后，美美哒~
***

# HEXO 常用命令

#### 一、在新环境中部署
若非 windows 平台，参考[链接](https://hexo.io/zh-cn/docs/index.html)。  
1. 安装 [Node.js](https://nodejs.org/en/) 和 [Git](https://git-scm.com/)
2. 安装 hexo：`npm install hexo`
3. 先初始化 hexo：`hexo init wenzhou & cd wenzhou`
4. 从自己早已准备好的仓库中pull下来
    ```bash
    $ git remote add origin https://github.com/wz2671/wz2671.github.io
    $ git pull origin hexo
    ```
5. 就可以生成 `hexo g` 和预览了 `hexo s`

* 配置文件`_config.yml`详解可参考 [Configuration](https://hexo.io/docs/configuration)

#### 二、命令备忘录
```bash
$ hexo new "article"    # 在 `source/_posts`下生成文章
$ hexo new draft "article"  # 在 `source/_draft`下生成草稿
$ hexo server --drafts  # 可预览草稿
```

***
