# Springboot的Demo App

## App概要

采取和实际项目采用的Springboot，Spring Cloud的版本一样。版本分别如下

- JDK:  1.8
- Springboot:  2.7.12
- SpringCloud:  2021.0.5

## 环境准备

### 编译方法

#### 编译

```shell
./mvnw clean package -DskipTests
```

#### 打包镜像

```shell
docker build -t app:1.0 .
```

#### 启动

```shell
docker run -p 8080:8080 app:1.0
```
启动应用后访问下列URL

##### Spring Actuator的Metrics

通过以下URL 可以看到获取Actuator的Metrics方法

[http://localhost:8080/actuator/metrics](http://localhost:8080/actuator/metrics)

##### Spring Actuator的Metrics(Promtheus格式)


通过以下URL 可以看到Prometheus格式的Metrics方法

[http://localhost:8090/actuator/prometheus](http://localhost:8090/actuator/prometheus)

输出格式参考promethues格式的输出.txt