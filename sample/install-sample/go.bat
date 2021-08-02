set THIS=%~dp0
set STYLESHEET=%THIS%xsl/xsd2html.xsl
set SAXONCFG=cp:/com/nkutsche/xsd2svg/saxon/saxon-config.xml

set SAXON_ARGS=-config:%SAXONCFG% ^
-xsl:%STYLESHEET% ^
-s:%THIS%xsd/config.xsd ^
-o:docs/config.html

set JARGS=-classpath %%%%classpath -Djava.protocol.handler.pkgs=top.marchand.xml.protocols net.sf.saxon.Transform %SAXON_ARGS%

call mvn exec:exec -Dexec.executable="java" -Dexec.args="%JARGS%"