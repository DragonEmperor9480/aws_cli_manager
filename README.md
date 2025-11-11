
# AWS CLI Manager (awsmgr)

A CLI tool to manage various AWS services such as IAM, EC2, and S3 through an interactive terminal interface.

---

## About

This project is a Go-based rewrite and enhancement of the original [awsmgr](https://github.com/DragonEmperor9480/awsmgr) bash script project by DragonEmperor9480.  
It provides a modular architecture to interact with AWS services using a user-friendly command-line interface.

---

## Features

- Interactive menus for managing AWS IAM, EC2, and S3 services.
- Modular structure with separate controllers and views for each service.
- Colored and formatted terminal output for improved UX.
- Under development: EC2 management features coming soon.
- Easily extensible to add more AWS service modules.

---

## Project Structure

- `controllers/` — Contains service-specific logic and menu handlers (e.g., IAM_mgr, EC2_mgr).
- `views/` — Contains UI components for menus and prompts.
- `utils/` — Utility functions like color codes, input helpers, animations, etc.
- `models/` — (Reserved for future) Data models or structs representing AWS entities.

---

## Getting Started

### Prerequisites

- Go installed (version 1.24.3 or newer recommended)
- AWS CLI configured on your machine (for actual AWS command executions)

### Installation Options

#### Option 1: Compile and Install to System Path

This method installs `awsmgr` globally so you can run it from anywhere:

```bash
# Clone the repository
git clone https://github.com/DragonEmperor9480/aws_cli_manager
cd aws_cli_manager

# Build the application
go build -o awsmgr

# Move to system path (requires sudo)
sudo mv awsmgr /usr/local/bin/

# Verify installation
awsmgr --version
```

After installation, you can run `awsmgr` from any directory.

#### Option 2: Quick Run (Local Build)

This method builds and runs the application locally without system installation:

```bash
# Clone the repository
git clone https://github.com/DragonEmperor9480/aws_cli_manager
cd aws_cli_manager

# Build the application
go build -o awsmgr

# Run the application
./awsmgr
```

You should see the interactive menu interface, allowing you to navigate AWS services.

#### Option 3: Windows Installation

For Windows users, follow these steps:

**Quick Run (Local Build):**

```powershell
# Clone the repository
git clone https://github.com/DragonEmperor9480/aws_cli_manager
cd aws_cli_manager

# Build the application
go build -o awsmgr.exe

# Run the application
.\awsmgr.exe
```

**To install globally (add to PATH):**

```powershell
# Clone the repository
git clone https://github.com/DragonEmperor9480/aws_cli_manager
cd aws_cli_manager

# Build the application
go build -o awsmgr.exe

# Create awsmgr directory in Program Files
mkdir "C:\Program Files\awsmgr"

# Move the executable
move awsmgr.exe "C:\Program Files\awsmgr\"

# Add to User PATH (run as administrator for System PATH)
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$userPath;C:\Program Files\awsmgr", "User")

# Restart your terminal and verify
awsmgr --version
```

After adding to PATH, you can run `awsmgr` from any directory.

---

## Usage

- Choose the service you want to manage (IAM, EC2, S3).
- Navigate submenus to perform tasks like creating users, managing buckets, etc.
- Use the menus to return to previous screens or exit the program.

---

## Contributing

Contributions and improvements are welcome! Feel free to open issues or submit pull requests.

---

## License

This project is open source and available under the MIT License.

---

## Acknowledgments

This project is ported and inspired by the original bash-based AWS manager available at:  
[https://github.com/DragonEmperor9480/awsmgr](https://github.com/DragonEmperor9480/awsmgr)

---
