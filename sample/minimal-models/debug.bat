set THIS=%~dp0
set STYLESHEET=%THIS%xsl/xsd2html.xsl
set SAXONCFG=%THIS%xsl/cfg/saxon-config.xml
set POM=%THIS%../../pom.xml

set SAXON_ARGS=-config:%SAXONCFG% ^
-xsl:%STYLESHEET% ^
-s:%THIS%in.xml ^
-o:out.xml

set JARGS=%DEBUG_ATTACH% ^
-classpath %%%%classpath net.sf.saxon.Transform %SAXON_ARGS%

call mvn -e -f %POM% compile exec:exec -Dexec.executable="java" -Dexec.args="%JARGS%"