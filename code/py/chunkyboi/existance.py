import argparse


def run_transform(data, transform):
    """
    Repeatedly run transform(data) until the transform reports Done.

    transform must return:
        (new_data, status)

    Example:
        Data0, "InProgress"
        Data1, "InProgress"
        Data2, "Done"
    """

    while True:
        data, status = transform(data)

        if status == "Done":
            return data

        if status != "InProgress":
            raise ValueError(f"Unknown transform status: {status}")


def compress(data):
    """
    Replace this with your compression transformation.

    Must return:
        (data, "InProgress")
    or:
        (data, "Done")
    """

    # Example placeholder
    return data, "Done"


def decompress(data):
    """
    Replace this with your decompression transformation.

    Must return:
        (data, "InProgress")
    or:
        (data, "Done")
    """

    # Example placeholder
    return data, "Done"


def process_file(input_file, transform):
    with open(input_file, "rb") as file:
        raw_data = file.read()

    result = run_transform(raw_data, transform)

    return result


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", required=True, help="Input file")
    parser.add_argument("--output", help="Output file")

    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--compress", action="store_true", help="Compress the input file")
    mode.add_argument("--decompress", action="store_true", help="Decompress the input file")

    args = parser.parse_args()

    if args.compress:
        transform = compress
        default_output = args.input + ".compressed"
    else:
        transform = decompress
        default_output = args.input + ".decompressed"

    output_file = args.output or default_output

    result = process_file(args.input, transform)

    with open(output_file, "wb") as file:
        file.write(result)

    print(f"Output written to: {output_file}")


if __name__ == "__main__":
    main()
