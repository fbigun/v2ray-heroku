*   [部署](/categories/deployment)
*    > [使用Docker进行部署](/categories/deploying-with-docker)
*    > 容器注册表和运行时（Docker部署）

# 容器注册表和运行时（Docker部署）

最后更新于2019年5月2日

## 目录

*   [入门](#getting-started)
*   [登录注册表](#logging-in-to-the-registry)
*   [建立和推动图像](#building-and-pushing-image-s)
*   [释放图像](#releasing-an-image)
*   [一次性dynos](#one-off-dynos)
*   [使用CI / CD平台](#using-a-ci-cd-platform)
*   [发布阶段](#release-phase)
*   [Dockerfile命令和运行时](#dockerfile-commands-and-runtime)
*   [在本地测试图像](#testing-an-image-locally)
*   [堆栈图像](#stack-images)
*   [更改部署方法](#changing-deployment-method)
*   [已知问题和限制](#known-issues-and-limitations)</div>

Heroku Container Registry允许您将Docker镜像部署到Heroku。这两种[常见的运行](https://devcenter.heroku.com/articles/dyno-runtime#common-runtime)和[私人空间](https://devcenter.heroku.com/articles/private-spaces)的支持。

如果您希望Heroku构建您的Docker镜像，以及利用Review Apps，请查看[使用heroku.yml构建Docker镜像](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml)。

## [入门](https://devcenter.heroku.com/articles/container-registry-and-runtime#getting-started)

确保你有一个有效的Docker安装（例如`docker ps`），并且你已经登录到Heroku（`heroku login`）。

登录Container Registry：

```
heroku container:login</span>
```

通过克隆基于Alpine的python示例获取示例代码：

```
git clone https://github.com/heroku/alpinehelloworld.git</span>
```

导航到应用程序的目录并创建一个Heroku应用程序：

```
$ heroku create
    Creating salty-fortress-4191... done, stack is heroku-16
    https://salty-fortress-4191.herokuapp.com/ | https://git.heroku.com/salty-fortress-4191.git
```

构建映像并推送到Container Registry：

```bash
$ heroku container:push web
```

然后将图像发布到您的应用：

```
$ heroku container:release web
```

现在在浏览器中打开应用程序：

```
$ heroku open
```

## [登录注册表](https://devcenter.heroku.com/articles/container-registry-and-runtime#logging-in-to-the-registry)

Heroku运行容器注册表`registry.heroku.com`。

如果您使用的是Heroku CLI，则可以使用以下命令登录：

```
$ heroku container:login
```

或直接通过Docker CLI：

```
$ docker login --username=_ --password=$(heroku auth:token) registry.heroku.com
```

## [建立和推动图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#building-and-pushing-image-s)

### [构建图像并推送](https://devcenter.heroku.com/articles/container-registry-and-runtime#build-an-image-and-push)

要构建映像并将其推送到Container Registry，请确保您的目录包含Dockerfile并运行：

```
$ heroku container:push <process-type>
```

### [推送现有图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#pushing-an-existing-image)

要将图像推送到Heroku，例如从Docker Hub拉出的图像，请根据此命名模板对其进行标记并推送：

```
$ docker tag <image> registry.heroku.com/<app>/<process-type>
$ docker push registry.heroku.com/<app>/<process-type>
```

通过在标记中指定流程类型，可以[使用CLI释放映像](#cli)。如果你宁愿不指定标签的工艺类型，你必须[通过API释放](#api)它使用`image_id`。

### [推送多个图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#pushing-multiple-images)

要推送多个图像，请使用`Dockerfile.<process-type>`以下命令 **重命名Dockerfiles** ：

```
$ ls -R

./webapp:
Dockerfile.web

./worker:
Dockerfile.worker

./image-processor:
Dockerfile.image
```

然后，从项目的根目录运行：

```
$ heroku container:push --recursive
=== Building web
=== Building worker
=== Building image
=== Pushing web
=== Pushing worker
=== Pushing image
```

这将构建并推送所有3个图像。如果您只想推送特定图像，则可以指定过程类型：

```
$ heroku container:push web worker --recursive
=== Building web
=== Building worker
=== Pushing web
=== Pushing worker
```

## [释放图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#releasing-an-image)

### [CLI](https://devcenter.heroku.com/articles/container-registry-and-runtime#cli)

成功将图像推送到Container Registry后，您可以使用以下命令创建新版本：

```
$ heroku container:release web
```

如果您有多个图像，请列出它们：

```
$ heroku container:release web worker
```

<div class="note">

在具有多种流程类型的应用程序中，如果仅释放一种流程类型（例如，`heroku container:release web`），则将重新启动所有流程类型。

</div>

### [API](https://devcenter.heroku.com/articles/container-registry-and-runtime#api)

```bash
curl -n -X PATCH https://api.heroku.com/apps/$APP_ID_OR_NAME/formation
  -d '{
  "updates": [
  {
    "type": "web",
    "docker_image": "$WEB_DOCKER_IMAGE_ID"
  },
  {
    "type": "worker",
    "docker_image": "$WORKER_DOCKER_IMAGE_ID"
  },
  ]
}' \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.heroku+json; version=3.docker-releases"
```

### [获取Docker镜像ID](https://devcenter.heroku.com/articles/container-registry-and-runtime#getting-a-docker-image-id)

```
$ docker build -t my_image .
...
Successfully built acf835bc07f5
Successfully tagged my_image:latest

$ docker inspect my_image --format={{.Id}}
acf835bc07f5
```

## [一次性dynos](https://devcenter.heroku.com/articles/container-registry-and-runtime#one-off-dynos)

如果您的应用程序由多个Docker镜像组成，则可以在创建一次性dyno时定位流程类型：

```
$ heroku run bash --type=worker
Running bash on ? multidockerfile... up, worker.5180
$
```

如果未指定类型，`web`则使用图像。

## [使用CI / CD平台](https://devcenter.heroku.com/articles/container-registry-and-runtime#using-a-ci-cd-platform)

<div class="note">
目前，无法使用Heroku CI来测试容器构建。
</div>

如果您使用的是第三方CI / CD平台，则可以将图像推送到注册表。首先使用以下信息进行身份验证：

*   注册网址： `registry.heroku.com`
*   用户名： `your Heroku email address`
*   电子邮件： `your Heroku email address`
*   密码： `your Heroku API key`

许多CI / CD提供程序都有关于如何构建和将图像推送到Docker注册表的文档：

*   [CircleCI](https://circleci.com/docs/2.0/custom-images/#storing-images-in-a-docker-registry)
*   [竹](https://confluence.atlassian.com/bamboo/configuring-the-docker-task-in-bamboo-720411254.html#ConfiguringtheDockertaskinBamboo-push)
*   [TravisCI](https://docs.travis-ci.com/user/docker/#Pushing-a-Docker-Image-to-a-Registry)
*   [詹金斯](https://wiki.jenkins-ci.org/display/JENKINS/CloudBees+Docker+Build+and+Publish+plugin)
*   [Codeship](https://documentation.codeship.com/pro/getting-started/docker-push/)

## [发布阶段](https://devcenter.heroku.com/articles/container-registry-and-runtime#release-phase)

要使用[发布阶段，请](https://devcenter.heroku.com/articles/release-phase)按下名为的Docker镜像`release`：

```
$ heroku container:push release
```

当您通过运行释放Docker镜像时，`heroku container:release`需要指定发布阶段过程类型：

```
$ heroku container:release web release
Releasing images web,release to your-app-name... done
Running release command...
Migrating database.
```

<div class="note">
如果您希望在执行发布阶段时看到流日志，则需要Docker镜像`curl`。如果您的Docker映像不包含`curl`，则应用程序日志中将提供发布阶段日志。如果您使用[Heroku-16](https://devcenter.heroku.com/articles/heroku-16-stack#heroku-16-docker-image)或[Heroku-18](https://devcenter.heroku.com/articles/heroku-18-stack)作为基本图像，`curl`则包括在内。
</div>

## [Dockerfile命令和运行时](https://devcenter.heroku.com/articles/container-registry-and-runtime#dockerfile-commands-and-runtime)

Docker镜像[以与slug相同的方式](https://devcenter.heroku.com/articles/dynos)在[dynos中](https://devcenter.heroku.com/articles/dynos)运行，并且在相同的约束条件下：

*   Web进程必须侦听`$PORT`由Heroku设置的HTTP流量。`EXPOSE`in `Dockerfile`不受尊重，但可用于本地测试。仅支持HTTP请求。
*   不支持dynos的网络链接。
*   文件系统是短暂的。
*   工作目录是`/`。您可以使用设置不同的目录`WORKDIR`。
*   `ENV`，用于设置环境变量，受支持。

    *   我们建议使用`ENV`运行时变量（例如`GEM_PATH`）和`heroku config`凭据，以便敏感凭证不会被意外地检入源代码控制。

*   `ENTRYPOINT`是可选的。如果没有设置，`/bin/sh -c`将被使用

    *   `CMD`将始终由shell执行，以便[配置变量](https://devcenter.heroku.com/articles/config-vars)可供您的进程使用; 执行单个二进制文件或使用没有shell的图像请使用`ENTRYPOINT`

<div class="note">
我们强烈建议您以非root用户身份在本地测试图像，因为**容器不能在Heroku上以root权限运行**。
</div>

### [不支持的Dockerfile命令](https://devcenter.heroku.com/articles/container-registry-and-runtime#unsupported-dockerfile-commands)

*   `VOLUME` - 不支持卷安装。[dyno](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem)的[文件系统是短暂的](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem)。
*   `EXPOSE`- 虽然`EXPOSE`可以用于本地测试，但Heroku的容器运行时不支持它。相反，您的Web进程/代码应该获得$ PORT环境变量。
*   `STOPSIGNAL`-  dyno管理器会通过发送[SIGTERM信号](https://devcenter.heroku.com/articles/dynos#graceful-shutdown-with-sigterm)，然后发送SIGKILL信号来请求您的进程正常关闭。  `STOPSIGNAL`不受尊重。
*   `SHELL`-  Docker镜像的默认shell `/bin/sh`，您可以`ENTRYPOINT`根据需要覆盖。
*   `HEALTHCHECK`- 虽然`HEALTHCHECK`目前不支持，但Heroku Dyno管理器会自动检查正在运行的容器的运行状况。

## [在本地测试图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#testing-an-image-locally)

在本地测试图像时，有许多最佳实践。这个最佳实践在此[示例Dockerfile](https://github.com/heroku/alpinehelloworld/blob/master/Dockerfile)中实现。

### [以非root用户身份运行映像](https://devcenter.heroku.com/articles/container-registry-and-runtime#run-the-image-as-a-non-root-user)

我们强烈建议您在本地测试图像作为非root用户，因为容器不能在Heroku中以root权限运行。在`CMD`您可以将以下命令添加到Dockerfile之前：

如果使用Alpine：

```Docker
RUN adduser -D myuser
USER myuser
```

如果使用Ubuntu：

```Docker
RUN useradd -m myuser
USER myuser
```

要确认您的容器是否以非root用户身份运行，请附加到正在运行的容器，然后运行以下`whoami`命令：

```
$ docker exec <container-id> bash
$ whoami
myuser
```

当部署到Heroku时，我们还以非root用户身份运行您的容器（尽管我们不使用`USER`Dockerfile中指定的容器）。

```
$ heroku run bash
$ whoami
U7729
```

### [从环境变量获取端口](https://devcenter.heroku.com/articles/container-registry-and-runtime#get-the-port-from-the-environment-variable)

出于测试目的，我们建议您`Dockerfile`或代码从$ PORT环境变量中读取，例如：

```
CMD gunicorn --bind 0.0.0.0:$PORT wsgi
```

在本地运行Docker容器时，可以使用-e标志设置环境变量：

```
$ docker run -p 5000:5000 -e PORT=5000 <image-name>
```

### [设置多个环境变量](https://devcenter.heroku.com/articles/container-registry-and-runtime#setting-multiple-environment-variables)

在本地使用heroku时，可以在[.env文件中](https://devcenter.heroku.com/articles/heroku-local#set-up-your-local-environment-variables)设置配置变量。何时`heroku local`运行.env被读取并且每个名称/值对都在环境中设置。使用Docker时可以使用相同的.env文件：

```
$ docker run -p 5000:5000 --env-file .env <image-name>
```

我们建议将.env文件添加到[.dockerignore文件中](https://docs.docker.com/engine/reference/builder/#dockerignore-file)。

### [利用Docker Compose实现多容器应用程序](https://devcenter.heroku.com/articles/container-registry-and-runtime#take-advantage-of-docker-compose-for-multi-container-applications)

如果您已创建多容器应用程序，则可以使用Docker Compose来定义本地开发环境。了解如何[使用Docker Compose进行本地开发](https://devcenter.heroku.com/articles/local-development-with-docker-compose)。

### [学到更多](https://devcenter.heroku.com/articles/container-registry-and-runtime#learn-more)

*   有关在本地运行Docker镜像的更多信息，请参阅[Docker的官方文档](https://docs.docker.com/engine/reference/run/)。
*   了解有关使用[Docker Compose进行本地开发的](https://devcenter.heroku.com/articles/local-development-with-docker-compose)更多信息。

## [堆栈图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#stack-images)

在[Heroku的-16](https://devcenter.heroku.com/articles/heroku-16-stack)和[Heroku的-18](https://devcenter.heroku.com/articles/heroku-18-stack)堆栈可作为泊坞的图像。但是，您可以自由使用任何所需的基本图像 - 不需要使用Heroku堆栈图像。如果您选择使用Heroku图像，我们建议使用Heroku-18（406MB）。

要使用Heroku-18作为基本图像`Dockerfile`：

```
FROM heroku/heroku:18
```

### [获取最新图像](https://devcenter.heroku.com/articles/container-registry-and-runtime#getting-the-latest-image)

如果您已经使用Heroku-18作为基本映像部署了应用程序，并希望获得[最新版本](https://hub.docker.com/r/heroku/heroku/builds/)（通常包括安全更新），只需运行：

```
$ docker pull heroku/heroku:18
```

并重新部署您的申请。

## [更改部署方法](https://devcenter.heroku.com/articles/container-registry-and-runtime#changing-deployment-method)

通过Container Registry部署应用程序后，堆栈将设置为`container`。这意味着您的应用程序不再使用[Heroku策划的堆栈](https://devcenter.heroku.com/articles/stack)，而是使用您自己的自定义容器。设置为`container`通过git推送您的应用程序被禁用。如果您不再希望通过Container Registry部署您的应用程序，而是想要使用git，请运行`heroku stack:set heroku-18`。

## [已知问题和限制](https://devcenter.heroku.com/articles/container-registry-and-runtime#known-issues-and-limitations)

*   不支持审核应用。要将Docker与评论应用程序一起使用，您可以使用[heroku.yml清单](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml)定义您的应用程序，该[清单](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml)允许您在Heroku上构建Docker镜像。
*   虽然Docker镜像不受尺寸限制（与[slugs](https://devcenter.heroku.com/articles/limits#slug-size)不同），但它们受制于[dyno启动时间限制](https://devcenter.heroku.com/articles/limits#boot-timeout)。随着层数/图像大小的增加，dyno启动时间也会增加。
*   超过40层的图像可能无法在Common Runtime中启动
*   不支持管道促销。
*   [此处列出](https://devcenter.heroku.com/articles/container-registry-and-runtime#unsupported-dockerfile-commands)的[命令](https://devcenter.heroku.com/articles/container-registry-and-runtime#unsupported-dockerfile-commands)不受支持。

### <span class="icon-book-open"></span>[继续阅读](#keep-reading)

* [使用Docker进行部署](/categories/deploying-with-docker)
* [Dynos和Dyno经理](/articles/dynos)
* [使用heroku.yml构建Docker镜像](/articles/build-docker-images-heroku-yml)
* [Heroku-16 Stack](/articles/heroku-16-stack)

### [反馈](#feedback)

[登录以提交反馈。](/login?back_to=%2Farticles%2Fcontainer-registry-and-runtime&utm_campaign=login&utm_medium=feedback&utm_source=web)

