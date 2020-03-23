suite = {
  "name" : "truffle-dhall",
  "mxversion" : "5.256.3",
  "versionConflictResolution": "latest",
  "groupId" : "com.pthariensflame.truffle-dhall",
  "url" : "https://github.com/pthariensflame/truffle-dhall",
  "developer" : {
    "name" : "Alexander Ronald Altman",
    "email" : "alexanderaltman@me.com",
  },
  "defaultLicense" : "BSD-3-Clause",
  "licenses" : {
    "BSD-3-Clause" : {
      "name" : "3-Clause BSD License",
      "url" : "https://opensource.org/licenses/BSD-3-Clause",
    }
  },
  "scm" : {
    "url" : "https://github.com/pthariensflame/truffle-dhall",
    "read" : "https://github.com/pthariensflame/truffle-dhall.git",
    "write" : "git@github.com:pthariensflame/truffle-dhall.git",
  },
  "imports" : {
    "suites": [
    ]
  },
  "libraries" : {
    "KOTLIN_STDLIB" : {
      "sha1" : "04defc79915cf4f78b49bbc4a8f1e80e87767a5b",
      "maven" : {
        "groupId" : "org.jetbrains.kotlin",
        "artifactId" : "kotlin-stdlib-jdk8",
        "version" : "1.3.71",
      }
    },
    "KOTLIN_MAVEN_PLUGIN" : {
      "sha1" : "0cde91e9ea8f9f7aaecc8a1c3373ff90924795c3",
      "maven" : {
        "groupId" : "org.jetbrains.kotlin",
        "artifactId" : "kotlin-maven-plugin",
        "version" : "1.3.71",
      }
    },
    "JLINE" : {
      "sha1" : "d3c97ca029afb0db85727bee53cb5a3e1de73598",
      "maven" : {
        "groupId" : "org.jline",
        "artifactId" : "jline",
        "version" : "3.14.0",
      }
    },
    "JLINE_JANSI" : {
      "sha1" : "70ab53c1c3d610392905835ed5ecfebb0381c334",
      "maven" : {
        "groupId" : "org.jline",
        "artifactId" : "jline-terminal-jansi",
        "version" : "3.14.0",
      }
    },
    "ANTLR4": {
      "sha1" : "7fe453b678b71c87c6677cef26f6b0cd96b26586",
      "maven" : {
        "groupId" : "org.antlr",
        "artifactId" : "antlr4-runtime",
        "version" : "4.8",
      }
    },
    "ANTLR4_COMPLETE": {
      "urls": ["https://www.antlr.org/download/antlr-4.8-complete.jar"],
      "sha1": "a675db077abf60d720f80f968602be763131820c",
    },
    "GRAALVM_SDK" : {
      "sha1" : "8ad38d2054bf7c56d1b0286c821117ddbfd5c4a4",
      "maven" : {
        "groupId" : "org.graalvm.sdk",
        "artifactId" : "graal-sdk",
        "version" : "20.0.0",
      }
    },
    "GRAALVM_LAUNCHER_COMMON" : {
      "sha1" : "b5ef343760646ca50c606bbec06813667ac373e0",
      "maven" : {
        "groupId" : "org.graalvm.sdk",
        "artifactId" : "launcher-common",
        "version" : "20.0.0",
      }
    },
    "TRUFFLE_API" : {
      "sha1" : "babdf30d5bc62bcce62dee85bd85f42e03841693",
      "maven" : {
        "groupId" : "org.graalvm.truffle",
        "artifactId" : "truffle-api",
        "version" : "20.0.0",
      }
    },
    "TRUFFLE_DSL_PROCESSOR" : {
      "sha1" : "1bebaf29c8e44c659b440ca714aa1afaaa86e922",
      "maven" : {
        "groupId" : "org.graalvm.truffle",
        "artifactId" : "truffle-dsl-processor",
        "version" : "20.0.0",
      }
    },
    "JUNIT_JUPITER" : {
      "sha1" : "4ae716895f1ee8a5720c02c8f2ae749bf7f7de18",
      "maven" : {
        "groupId" : "org.junit.jupiter",
        "artifactId" : "junit-jupiter",
        "version" : "5.6.1",
      }
    },
    "JUNIT_PLATFORM_RUNNER" : {
      "sha1" : "a86118155b3b45049a176980d781b5a09c420878",
      "maven" : {
        "groupId" : "org.junit.platform",
        "artifactId" : "junit-platform-runner",
        "version" : "1.6.1",
      }
    },
  },
  "projects" : {
    "com.pthariensflame.truffle_dhall": {
      "subDir": "truffle_dhall",
      "sourceDirs": ["src"],
      "dependencies": [
        "TRUFFLE_API",
        "GRAALVM_SDK",
        "ANTLR4",
      ],
      "buildDependencies": ["com.pthariensflame.truffle_dhall.parser.antlr"],
      "jacoco": "include",
      "javaCompliance": "11+",
      "checkstyleVersion": "8.30",
      "annotationProcessors": ["TRUFFLE_DSL_PROCESSOR"],
      "spotbugsIgnoresGenerated": True,
    },
    "com.pthariensflame.truffle_dhall.parser.antlr": {
      "subDir": "truffle_dhall",
      "buildEnv": {
        "ANTLR_JAR": "<path:ANTLR4_COMPLETE>",
        "PARSER_PATH": "<src_dir:com.pthariensflame.truffle_dhall>/com/pthariensflame/truffle_dhall/parser/antlr",
        "PARSER_PKG": "com.pthariensflame.truffle_dhall.parser.antlr",
      },
      "dependencies": [
        "ANTLR4_COMPLETE",
      ],
      "jacoco": "include",
      "native": True,
      "vpath": False,
    },
    "com.pthariensflame.truffle_dhall.shell": {
      "subDir": "truffle_dhall",
      "sourceDirs": ["src"],
      "dependencies": [
        "TRUFFLE_API",
        "GRAALVM_SDK",
        "ANTLR4",
      ],
      "buildDependencies": ["com.pthariensflame.truffle_dhall.parser.antlr"],
      "jacoco": "include",
      "javaCompliance": "11+",
      "checkstyleVersion": "8.30",
      "annotationProcessors": ["TRUFFLE_DSL_PROCESSOR"],
      "spotbugsIgnoresGenerated": True,
    },
  },
  "distributions": {
    "TRUFFLE-DHALL-LAUNCHER": {
      "dependencies": [
        "com.pthariensflame.truffle_dhall.shell",
      ],
      "distDependencies": [
        "GRAALVM_SDK",
        "GRAALVM_LAUNCHER_COMMON",
      ],
      "description": "Truffle-Dhall launcher",
    },
    "TRUFFLE-DHALL": {
      "dependencies": [
        "com.pthariensflame.truffle_dhall",
      ],
      "distDependencies": [
        "TRUFFLE-DHALL-LAUNCHER",
        "TRUFFLE_API",
        "GRAALVM_SDK",
        "ANTLR4",
      ],
      "sourcesPath": "truffle_dhall.src.zip",
      "description": "Truffle-Dhall engine",
    },

  }
}
