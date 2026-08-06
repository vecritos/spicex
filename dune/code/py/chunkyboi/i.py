import os
import sys
import time
import tempfile
import hashlib
import argparse
import importlib.util

class SimpleProgressBar:
    def __init__(self, total_bytes, quiet=False, label="Progress"):
        self.total = total_bytes
        self.quiet = quiet
        self.label = label
        self.start_time = None
        self.processed = 0

    def start(self):
        if not self.quiet:
            self.start_time = time.time()
            self.processed = 0
            self._print(0, 0)

    def update(self, bytes_processed):
        if self.quiet or self.start_time is None:
            return
        self.processed += bytes_processed
        elapsed = time.time() - self.start_time
        if self.processed == 0:
            eta = "??:??:??"
        else:
            rate = self.processed / elapsed
            remaining = (self.total - self.processed) / rate if rate > 0 else 0
            eta = time.strftime("%H:%M:%S", time.gmtime(remaining))

        percent = (self.processed / self.total) * 100 if self.total else 0
        bar_len = 30
        filled_len = int(bar_len * self.processed // self.total) if self.total else 0
        bar = "=" * filled_len + "-" * (bar_len - filled_len)

        self._print(percent, eta, bar)

    def _print(self, percent, eta, bar=""):
        # Overwrite current line
        sys.stdout.write(f"\r{self.label}: [{bar}] {percent:6.2f}% ETA: {eta}")
        sys.stdout.flush()

    def finish(self):
        if not self.quiet:
            # Print newline to end progress bar cleanly
            print()

def load_transform_function(path):
    spec = importlib.util.spec_from_file_location("transform_module", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not hasattr(mod, "transform"):
        raise AttributeError("Transform module must define a 'transform(data: bytes, **kwargs) -> bytes' function")
    return mod.transform

def default_transform(data, **kwargs):
    # Endian-flip + reverse bits fallback
    return data[::-1]

def run_pipeline_iteration(src_path, temp_dir, chunk_size, transform_fn, progress_bar, transform_kwargs):
    results = []
    with open(src_path, "rb") as src:
        index = 0
        while True:
            chunk = src.read(chunk_size)
            if not chunk:
                break
            transformed = transform_fn(chunk, **transform_kwargs)
            temp_path = os.path.join(temp_dir, f"chunk_{index:08d}.tmp")
            with open(temp_path, "wb") as tf:
                tf.write(transformed)
            results.append((index, temp_path, len(transformed), hashlib.sha256(transformed).hexdigest()))
            progress_bar.update(len(chunk))
            index += 1
    return results

def geometric_sum(input_size, reduction_factor, iterations):
    if reduction_factor == 1:
        return input_size * iterations
    return input_size * (1 - reduction_factor ** iterations) / (1 - reduction_factor)

def iterative_multi_stage_pipeline(input_path, output_path, bytes_to_remove_list, chunk_size=1024*1024, quiet=False, transform_path=None, transform_kwargs=None):
    transform_kwargs = transform_kwargs or {}
    if transform_path:
        transform_fn = load_transform_function(transform_path)
    else:
        transform_fn = default_transform

    total_iterations = len(bytes_to_remove_list)
    current_input = input_path
    temp_file = None
    cumulative_bytes_processed = 0
    reduction_factor = 1.0  # will update after first iteration

    # Prepare overall progress bar with dummy total, will update after first iteration
    overall_progress = SimpleProgressBar(total_bytes=1, quiet=quiet, label="Overall Progress")
    overall_progress.start()

    for iteration, byte_val in enumerate(bytes_to_remove_list, start=1):
        print(f"\nStage {iteration}/{total_iterations}: removing byte {byte_val}")

        # For this example, create a transform function that removes the byte
        def transform(data, remove_byte=byte_val):
            return data.replace(remove_byte, b'')

        # Measure transform time and output size on a test chunk (1MB or less)
        with open(current_input, "rb") as f:
            test_chunk = f.read(min(chunk_size, 1024*1024))
        start = time.time()
        test_output = transform_fn(test_chunk, **transform_kwargs) if transform_path else transform(test_chunk)
        elapsed = time.time() - start
        if len(test_chunk) == 0:
            time_per_byte = 0
            reduction_factor_iter = 1.0
        else:
            time_per_byte = elapsed / len(test_chunk)
            reduction_factor_iter = len(test_output) / len(test_chunk)

        # Update overall total bytes estimate after first iteration
        if iteration == 1:
            file_size = os.path.getsize(current_input)
            reduction_factor = reduction_factor_iter if reduction_factor_iter > 0 else 1.0
            total_expected_bytes = geometric_sum(file_size, reduction_factor, total_iterations)
            overall_progress.total = total_expected_bytes

        # Start iteration progress bar
        iteration_progress = SimpleProgressBar(total_bytes=os.path.getsize(current_input), quiet=quiet, label=f"Iteration {iteration} Progress")
        iteration_progress.start()

        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            temp_file = tmp.name

        # Run the iteration pipeline with either injected or built-in transform
        results = run_pipeline_iteration(
            current_input,
            os.path.dirname(temp_file),
            chunk_size,
            transform_fn if transform_path else transform,
            iteration_progress,
            transform_kwargs
        )
        iteration_progress.finish()

        # Merge and validate as usual
        sequential_merge_temp_files(output_path=temp_file, temp_files=results)
        validate_output_file(output_path=temp_file, metadata=[(idx, 0, length, hash_) for idx, _, length, hash_ in results])

        # Update overall progress and cumulative bytes
        cumulative_bytes_processed += os.path.getsize(current_input)
        overall_progress.update(os.path.getsize(current_input))
        overall_progress._print((cumulative_bytes_processed/overall_progress.total)*100, "??:??:??")  # update overall bar manually

        # Cleanup previous input if not original
        if current_input != input_path:
            try:
                os.remove(current_input)
            except OSError:
                pass

        current_input = temp_file

    overall_progress.finish()

    # Final move to output path
    if current_input != output_path:
        os.replace(current_input, output_path)
        print(f"\nFinal output written to {output_path}")

def sequential_merge_temp_files(output_path, temp_files):
    temp_files.sort(key=lambda x: x[0])
    current_offset = 0
    metadata = []
    with open(output_path, "wb") as out_f:
        for index, temp_path, length, hash_digest in temp_files:
            with open(temp_path, "rb") as f:
                while True:
                    buf = f.read(1024*1024)
                    if not buf:
                        break
                    out_f.write(buf)
            metadata.append((index, current_offset, length, hash_digest))
            current_offset += length
    return metadata

def validate_output_file(output_path, metadata):
    with open(output_path, "rb") as f:
        for index, offset, length, expected_hash in metadata:
            f.seek(offset)
            data = f.read(length)
            actual_hash = hashlib.sha256(data).hexdigest()
            if actual_hash != expected_hash:
                raise RuntimeError(f"Chunk {index} hash mismatch! Expected {expected_hash}, got {actual_hash}")

def main():
    parser = argparse.ArgumentParser(description="chunkyboi - iterative multi-stage file transform tool")
    parser.add_argument("input", help="Input file path")
    parser.add_argument("output", help="Output file path")
    parser.add_argument("--quiet", action="store_true", help="Disable progress bars")
    parser.add_argument("--config", help="Path to transform module or password string")
    parser.add_argument("--chunk-size", type=int, default=4*1024*1024, help="Chunk size in bytes (default 4MB)")
    args = parser.parse_args()

    # Determine transform path and bytes_to_remove_list based on config (simplified)
    # For demo: if config is file, use it, else treat as password string (dummy example)
    transform_path = None
    bytes_to_remove = [b'a', b'b', b'c']
    transform_kwargs = {}

    if args.config:
        if os.path.isfile(args.config):
            transform_path = args.config
        else:
            transform_kwargs['password'] = args.config

    iterative_multi_stage_pipeline(
        args.input,
        args.output,
        bytes_to_remove,
        chunk_size=args.chunk_size,
        quiet=args.quiet,
        transform_path=transform_path,
        transform_kwargs=transform_kwargs
    )

if __name__ == "__main__":
    main()

