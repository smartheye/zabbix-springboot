# Springboot+Zabbix监控指标输出

# Springboot程序

在[app/springserver](app/springserver)下是一个运用Springboot2.7做的demo程序。这个程序配置了actuator输出的metrics格式，并且同时提供了promethues格式输出的metrics

具体可以参考[app/springserver/README.md](app/springserver/REAMDE.md)

# Zabbix环境

参考[docker](docker)下的zabbix启动docker环境