
# Create CI Pipeline with Jenkinsfile

## Overview
This module covers creating Continuous Integration (CI) pipelines using Jenkins with different pipeline types: Freestyle jobs, Declarative Pipeline, and Multibranch Pipeline.

## Objectives
- Understand Jenkins pipeline fundamentals
- Create Freestyle job configurations
- Write Declarative Jenkinsfile syntax
- Implement Multibranch Pipeline for multiple branches
- Integrate with version control systems

## Pipeline Types

### 1. Freestyle Jobs
Traditional Jenkins job configuration through the UI.
- Manual job setup
- GUI-based configuration
- Best for simple pipelines

### 2. Pipeline (Jenkinsfile)
Code-as-infrastructure approach using Groovy DSL.
- Declarative or Scripted syntax
- Version-controlled pipeline definitions
- Better for complex workflows

### 3. Multibranch Pipeline
Automatically creates pipelines for different branches.
- Scans repository for Jenkinsfiles
- Isolated builds per branch
- Ideal for development workflows

## Getting Started

1. Install Jenkins and required plugins
2. Configure Git/GitHub integration
3. Create your first Jenkinsfile
4. Set up webhook triggers
5. Monitor pipeline execution

## Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkinsfile Syntax Reference](https://www.jenkins.io/doc/book/pipeline/)
