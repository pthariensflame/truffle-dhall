QUIETLY$(MX_VERBOSE) = @

# during clean, this isn't set
PARSER_PATH ?= ../com.pthariensflame.truffle_dhall/src/com/pthariensflame/truffle_dhall/parser/antlr

TARGETS=${PARSER_PATH}/DhallParser.java \
	${PARSER_PATH}/DhallLexer.java

SOURCE=${PARSER_PATH}/Dhall.g4
STAMP=${SOURCE}.stamp

.PHONY: default clean

default: ${TARGETS}

${STAMP}: ${SOURCE} # ${POSTPROCESSOR}
	$(QUIETLY) touch $@
	$(QUIETLY) ${JAVA_HOME}/bin/java -cp ${ANTLR_JAR} org.antlr.v4.Tool -no-listener -no-visitor -package ${PARSER_PKG} -o ${PARSER_PATH} ${SOURCE}

# # postprocessing to make source compile without warnings
# ${PARSER_PATH}/%.java: ${STAMP}
# 	python ${POSTPROCESSOR} $@

clean:
ifeq ($(wildcard ${SOURCE}),)
	$(error ${SOURCE} is not in the location I expected it to be, not cleaning antlr parser)
endif
	$(QUIETLY) rm -f ${TARGETS}
	$(QUIETLY) rm -f ${STAMP}
	$(QUIETLY) rm -f ${PARSER_PATH}/Dhall.tokens \
			${PARSER_PATH}/DhallLexer.tokens \
			${PARSER_PATH}/Dhall.interp \
			${PARSER_PATH}/DhallLexer.interp
