
编译：
./mvnw clean package -DskipTests

打包镜像：
docker build -t app:1.0 .   

启动：
docker run -p 8080:8080 app:1.0 

启动应用后访问：

http://localhost:8080/actuator/metrics 可以看到有哪些指标

常见 GC Pause 相关指标有：

jvm.gc.pause （GC 停顿时间分布直方图）

jvm.gc.memory.allocated

jvm.gc.memory.promoted

jvm.gc.max.data.size