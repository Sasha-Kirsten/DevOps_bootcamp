package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

public class AppTest {

    @Test
    void greetingIsStable() {
        assertEquals("Hello, Maven!", App.greeting());
    }
}