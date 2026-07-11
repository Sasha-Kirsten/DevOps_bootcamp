# Simple Maven Application

## Overview
This is a simple Maven application that demonstrates the basic structure of a Maven project.

## Project Structure
```
simple-maven-app
├── src
│   ├── main
│   │   └── java
│   │       └── com
│   │           └── example
│   │               └── App.java
│   └── test
│       └── java
│           └── com
│               └── example
│                   └── AppTest.java
├── pom.xml
└── README.md
```

## Getting Started

### Prerequisites
- Java Development Kit (JDK) installed
- Apache Maven installed

### Building the Application
To build the application, navigate to the project directory and run the following command:
```
mvn clean package
```

### Running the Application
After building the application, you can run it using the following command:
```
java -cp target/simple-maven-app-1.0-SNAPSHOT.jar com.example.App
```

### Running Tests
To run the unit tests, use the following command:
```
mvn test
```

## License
This project is licensed under the MIT License.