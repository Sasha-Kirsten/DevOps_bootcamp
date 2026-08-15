## Protect the Jenkins Controller
### Never Build on the Controller:
#### Ensure all pipelines execution happens on agent nodes rather than the controller's lightweight executors. 

### Dynamic Agent Provisioning:
#### Instead of maintaining static virtual machines, configure Jenkins to dynamically provision lightweight Docker containers as agents within a Kubernetes cluster. This scales your infrastructure efficiently during peak hours and terminates the containers when the job finishes, freeing up compute resources. 

### Discard Old Builds:
#### Accumulating thousands of old build logs and artifacts severely slows down the Jenkins filesystem and the UI. Always use the "Discard old builds" configuration in your jobs to keep only a specific number of recent runs.



## Optimize Groovy and Pipeline Code
### Use Groovy as Glue, Not Core Logic:
#### Use Groovy only to connect a set of actions rather than as the main functionality of your Pipeline. Rely on single steps (such as `sh`) to accomplish multiple parts of the build. As Pipeline complexity increases, more controller resources (CPU, memory, storage) are consumed.

### Offload Heavy Computation:
#### Groovy code in Jenkins pipelines executes directly on the controller, consuming its memory and CPU. Avoid using Groovy for heavy lifting — most critically `JsonSlurper`, which loads files into controller memory twice. Instead, use a shell step with `jq`: `def result = sh(returnStdout: true, script: 'echo "$LOCAL_FILE" | jq "$QUERY"')`. Similarly, replace `HttpRequest` with `curl` or `wget` in a shell step to offload the work to the agent.

### Minimize Step Repetition:
#### Every individual step in a pipeline (like `sh` or `echo`) requires Jenkins to establish connections and allocate resources. Combine multiple commands into a single `sh` block rather than chaining multiple individual shell steps sequentially.

### Handle User Inputs Outside Agents:
#### If your pipeline requires manual approval (an `input` step), place it outside of the `node` or `agent` block. Pausing for input inside an agent keeps the workspace locked and holds an executor hostage while waiting for a human.

### Avoid Calls to Jenkins.getInstance:
#### Using `Jenkins.instance` in a Pipeline creates severe security and performance risks. Any whitelisted method runs as the System user with admin permissions, granting developers higher permissions than intended. Instead, implement a minimal Jenkins plugin that safely wraps the required API using the Pipeline Step API.


## Improve Build Speeds:
### Parallel Execution:
#### Use the `parallel` directive in Declarative Pipelines to run independent stages simultaneously. This is highly effective for running unit tests across different modules or deploying to multiple lower environments at once. 

### Efficient File Sharing:
#### When you need to pass files — like compiled binaries — from a build stage to a test stage, use the `stash` and `unstash` commands. This is faster and less resource-intensive than archiving artifacts, as it is designed specifically for temporary storage within the same pipeline run.


## JVM and System Tuning

### Garbage Collection (GC):
#### Switching to the Garbage First (G1GC) garbage collector significantly reduces pause times compared to the default parallel collector. This prevents the Jenkins UI from freezing or dropping agent connections during heavy loads.

### Heap Sizing:
#### Set your initial heap size (`-Xms`) and maximum heap size (`-Xmx`) appropriately, often keeping the initial size close to or equal to the maximum to prevent the JVM from constantly resizing memory.


## Manage Serialization (Avoiding NotSerializableException)
### Ensure Variables Are Serializable:
#### Pipelines use Continuation-Passing Style (CPS) execution to support resuming after a Jenkins restart. Storing non-serializable objects in variables will throw a `NotSerializableException` when the pipeline tries to persist its state. Infer non-serializable values "just-in-time" rather than storing them in variables.

### Use @NonCPS Annotation Where Necessary:
#### Use `@NonCPS` to disable CPS transformation for a specific method whose body would not execute correctly if transformed. Be aware that asynchronous Pipeline steps (`sh`, `sleep`, etc.) **cannot** be used inside `@NonCPS` methods, and the annotated method will restart completely if the pipeline resumes.


## Manage Shared Libraries Efficiently
### Do Not Override Built-In Pipeline Steps:
#### Do not use shared libraries to overwrite standard Pipeline APIs like `sh` or `timeout`. These APIs can change at any time, making custom overrides fragile, unpredictable after updates, and difficult to debug.

### Avoid Large Global Variable Declaration Files:
#### Large variable files are loaded for every Pipeline execution regardless of whether the variables are needed, consuming unnecessary controller memory. Create small, focused variable files containing only variables relevant to the current execution.

### Avoid Very Large Shared Libraries:
#### Large shared libraries must be checked out before every Pipeline run and loaded per executing job, leading to increased memory overhead and slower startup times.


## Handle Concurrency Safely
### Use Distinct Workspaces:
#### Do not share workspaces across multiple Pipeline executions or distinct Pipelines. This can lead to unexpected file modifications or workspace renaming. Use cloud-type agents that create resources from scratch for each build, ensuring a clean and repeatable build process.

### Copy Files Instead of Sharing Volumes:
#### Mount shared volumes separately and copy only the needed files into the current workspace. Copy results back when the build is done rather than working directly on the shared volume.

### Use the Lockable Resources Plugin:
#### If building isolated containers is not an option, disable concurrency on the Pipeline or use the Lockable Resources Plugin to lock the workspace during execution, preventing other builds from using it simultaneously. Note that this approach results in slower time-to-results compared to using unique resources per job.


---


## Compare with GitHub Actions:
## Optimize Runner Execution:
### Use Self-Hosted Runners for Heavy Lifting:
#### If your builds require massive CPU or memory (like compiling large applications or running heavy intergration tests), GitHub's default runners will bottlneck you. Deploying self-hosted runners on your own infrastrucutre provides much faster compute times.

### Pre-Bake Your Toolchains:
#### If you use self-hosted runners, pre-install your heavy dependencies (like Node, Python or Java SDKs) directly onto the runner's image. This saves the pipeline from having to execute `actions/setup-*` steps on every single run. 

### Use Alpine for Container Actions:
#### If you build custom container actions, ensure they are based on lightweight images like Alpine. Forcing a runner to download a massive Ubuntu image just to execute a simple bash script adds unnecessary minutes to your build. 

## Master Caching Strategies:
### Cache Package Dependencies:
#### Use the official `actions/cache` or the built-in caching features of setup actions (like `actions/setup-node`) to store your `node_modules` or `pip` directories. Always bind the cache key to your dependency lockfile (`package-lock.json`) using `hashFiles()`, ensuring the cache only invalidates when dependencies actually change.

### Leverage Docker Layer Caching:
#### Building Docker Images from scratch on every commit is incredibly slow. Use BuildKit and pass the `cache-from` and `cache-to` arguments with `type=gha`. This allows Docker to store and pull intermediate image layers directly from the native GitHub Actions cache.

### Monitor the 10GB Limit:
#### GitHub caps repository cache storage at 10GB. If you are caching massive artifacts that change frequently, you will thrash the system, forcing GitHub to constantly evict old caches and resulting in slower "cold start" builds. 

## Workflow Architecture & Parallelization 
### Matrix Strategy: The `strategy.matrix` configuration is one of GitHub's most powerful features. Instead of running tests sequentially, a matrix configuration automatically spawns multiple concurrent runners to execute tasks (like testing across different Node versions or operating systems) simultaneously. 


## Reusable Workflows:
### Avoid copy-pasting the same build logic across multiple repositories. Use `workflow_call` to create centralized, modular workflows. If you discover a way to share 30 seconds off a build, updating the central workflow instantly speeds up to pipeline for every dependent project. 

## Fail Fast:
### When running matrix builds, `fail-fast:true` is enabled by default. Keep this on so that if one configuration in the matrix fails, GitHub instantly cancels all other parallel jobs, saving valuable Action minutes and compute resources. 


## Smart Trigger & Conditional Execution 
### Path Filtering:
#### Use the `paths` or `paths-ignore` keys in your `on: pash` or `on:pull_request` triggers. If a pull request only modifies a `.md` documentation file, you can intruct GitHub to completly skip the application build and test jobs.

### Concurrency Groups:
#### Use the `concurrency` key to cancel outdated pipeline runs. If a developer pushes a commit, realizes they made a typo, and pushes a fix 10 seconds later, a concurrency group will automatically cancel the first run a free up the runner for the latest code.

