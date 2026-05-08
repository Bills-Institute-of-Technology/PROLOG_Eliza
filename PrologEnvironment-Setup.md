# Prolog Environment Setup (Windows)

This guide will help you set up a Prolog development environment on Windows, including SWI-Prolog installation, VS Code integration, and essential configuration.

---

## 1. Download and Install SWI-Prolog

- Visit the official SWI-Prolog website: [https://www.swi-prolog.org/Download.html](https://www.swi-prolog.org/Download.html)
- Download the Windows installer (64-bit recommended).
- Run the installer and follow the prompts to complete installation.
- After installation, add SWI-Prolog to your system PATH if not done automatically.

**Verify Installation:**
- Open a new terminal (PowerShell or Command Prompt).
- Type `swipl` and press Enter. You should see the Prolog REPL prompt (`?-`).

---

## 2. Install VSC-Prolog Extension in VS Code

- Open Visual Studio Code.
- Go to Extensions (`Ctrl+Shift+X`).
- Search for `VSC-Prolog` and install it.
- Optionally, install the `SWI-Prolog` extension for additional features.

---

## 3. Configuration Specifics

### UTF-8 Encoding
- Ensure your Prolog source files are saved with UTF-8 encoding.
- In VS Code, check the encoding at the bottom right of the window. Change to UTF-8 if needed.
- In the terminal, set the code page to UTF-8 by running:
  ```powershell
  chcp 65001
  ```
- In Prolog, you can specify encoding in your source files:
  ```prolog
  :- set_prolog_flag(encoding, utf8).
  ```

### SWI-Prolog Settings in VS Code
- Open VS Code settings (`Ctrl+,`).
- Search for "Prolog" and review extension settings.
- Set the path to `swipl.exe` if not auto-detected.

---

## 4. Using the Prolog REPL

### Starting the REPL
- Open a terminal and type:
  ```powershell
  swipl
  ```
- You will see the prompt: `?-`

### Loading a Module/File
- At the REPL prompt, load a file:
  ```prolog
  ?- [main].
  ```
  (Assumes `main.pl` is in the current directory)

### Reloading a Module/File
- To reload after changes:
  ```prolog
  ?- [main].
  ```
  (Prolog reloads the file if it has changed)

### Tracing Execution
- To trace a query:
  ```prolog
  ?- trace, your_query.
  ```
- To stop tracing:
  ```prolog
  ?- notrace.
  ```

### Exiting the REPL
- To exit:
  ```prolog
  ?- halt.
  ```

---

## 5. Additional Tips
- Use `listing.` to view loaded predicates.
- Use `help(predicate).` for documentation.
- For more, see the [SWI-Prolog documentation](https://www.swi-prolog.org/pldoc/doc_for?object=manual).

---

*This document is intended for beginners setting up Prolog on Windows with VS Code.*
