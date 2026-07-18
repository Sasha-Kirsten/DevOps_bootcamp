package main.java.com.example.myapp;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Hello from MyApp! The application is running successfully.";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
