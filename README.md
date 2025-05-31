
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

### Clone the repository

```bash
git clone https://github.com/DragonEmperor9480/aws_cli_manager.git
cd aws_cli_manager
```

### Build the project

Build the binary executable using the following command:

```bash
go build -o out/awsmgr
```

This will compile the project and place the executable in the `out/` directory as `awsmgr`.

### Run the executable

```bash
./out/awsmgr
```

You should see the interactive menu interface, allowing you to navigate AWS services.

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
