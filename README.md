### dldw.sh

This is a shell script designed to interact with the DLsite website, allowing you to log in, list your purchased products, and download them.

#### Prerequisites

The script requires the following command-line tools to be installed on your system:

- `curl`: A tool for transferring data with URLs.
- `jq`: A lightweight and flexible command-line JSON processor.
- `aria2c`: A multi-protocol and multi-source command-line download utility.

The script will check for these dependencies and exit if any are missing.

#### Usage

The script supports two main subcommands: `login` and `product`.

##### `login` subcommand

This subcommand handles the authentication process. It requires you to provide your DLsite username and password.

```bash
./dldw.sh login --username <YOUR_USERNAME> --password <YOUR_PASSWORD>
```

Upon successful login, a `dlsite-cookie.txt` file will be created in the same directory, which stores the session cookies needed for subsequent commands.

##### `product` subcommand

This subcommand has two further options: `list` and `download`.

- **`list`**: Lists all the products you have purchased.

  ```bash
  ./dldw.sh product list
  ```

  The output will display the product work number (`WORKNO`) and the product name.

- **`download`**: Downloads a specific product using its `WORKNO`.

  ```bash
  ./dldw.sh product download <WORKNO>
  ```

  You can optionally specify a download directory using the `-d` or `--dir` flag. If not specified, the files will be downloaded to a `downloads` directory created in the same location as the script.

  ```bash
  ./dldw.sh product download <WORKNO> --dir /path/to/your/download/folder
  ```

  The script uses `aria2c` for downloads, leveraging its multi-connection capabilities for potentially faster downloads. It is configured to use 10 connections (`-x 10`) and 10 parallel downloads (`-s 10`).

#### Command-line Options

| Short Option | Long Option  | Description                                   | Subcommand |
| :----------- | :----------- | :-------------------------------------------- | :--------- |
| `-u`         | `--username` | Your DLsite login ID.                         | `login`    |
| `-p`         | `--password` | Your DLsite password.                         | `login`    |
| `-d`         | `--dir`      | The directory where files will be downloaded. | `product`  |
