package com.example;

public class App {
    static final String GREETING = "Hello, Maven!";

    private App() {
    }

    public static String greeting() {
        return GREETING;
    }

    public static void main(String[] args) {
        System.out.println(greeting());
    }
}