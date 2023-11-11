import argparse
import os
import tarfile
import zipfile


parser = argparse.ArgumentParser(
    description='Streams content from <archive.tar> to (uncompressed) <archive.zip>',
)
parser.add_argument(
    '--test',
    '-T',
    dest='test',
    action='store_true',
    help='Test the integrity of the new zip file. If the check fails and'
    ' (with the -m option) the source archive is not removed.',
)
parser.add_argument(
    '--move',
    '-m',
    dest='move',
    action='store_true',
    help='Move the specified files into the zip archive; actually, this deletes'
    ' the target directories/files after making the specified zip archive. If a'
    ' directory becomes empty after  removal of the files, the directory is'
    ' also removed. No deletions are done until zip has created the archive'
    ' without error.  This is useful for conserving disk space, but is'
    ' potentially dangerous so it is recommended to use it in combination with'
    ' -T to test the archive before removing all input files.',
)
parser.add_argument(
    '--clean-on-fail',
    action='store_true',
    help='If verification fails, remove broken zip.'
)
parser.add_argument(
    'tar_fn',
    metavar='<archive.tar>',
    nargs=1,
    type=str,
    help='Archive to be converted, if no match is found also tries with extra .tar.',
)


def strip_tar_file_extension(fn: str) -> str:
    if not fn.endswith('.tar'):
        raise ValueError(f'Archive filename "{fn}" doesn\'t end with .tar')
    return fn[:-4]


def tar2zip(tar_fn: str, zip_fn: str):
    if not os.path.isfile(tar_fn):
        raise ValueError(f'No such file {fn}')
    if os.path.exists(zip_fn):
        raise ValueError(f'Path {zip_fn} already exists.')

    # Based on https://stackoverflow.com/a/39265752/15399131 
    with tarfile.open(name=tar_fn, mode='r|') as tarf:
        with zipfile.ZipFile(file=zip_fn, mode='w', compression=zipfile.ZIP_STORED) as zipf:
            for m in tarf:
                if not m.isfile():
                    # for directories
                    continue
                f = tarf.extractfile(m)
                zipf.writestr(
                    m.name,
                    f.read(),
                    compress_type=zipfile.ZIP_STORED,
                )


def verify_result(tar_fn: str, zip_fn: str) -> bool:
    with tarfile.open(name=tar_fn, mode='r|') as tarf:
        tarf_fns, tarf_infos = zip(*[
            (m.name, m) for m in tarf
            if m.isfile()
        ])

    with zipfile.ZipFile(file=zip_fn, mode='r') as zipf:
        zipf_fns = zipf.namelist()

        if set(tarf_fns) != set(zipf_fns):
            raise RuntimeError(f'Different files found in archive.')

        zipf_info = zipf.infolist()
        for tm_info in tarf_infos:
            zm_info = zipf.getinfo(tm_info.name)
            if zm_info.file_size != tm_info.size:
                raise RuntimeError(f'{f} has different sizes in archives.')


def main():
    args = parser.parse_args()
    assert len(args.tar_fn) == 1
    tar_fn = args.tar_fn[0]
    zip_fn = strip_tar_file_extension(tar_fn) + '.zip'

    tar2zip(tar_fn, zip_fn)

    if args.test:
        # Throw error if archives differ in content
        try:
            verify_result(tar_fn, zip_fn)
        except RuntimeError:
            if args.clean_on_fail:
                os.remove(zip_fn)
            raise

    if args.move:
        print(f"Removing {tar_fn}...")
        os.remove(tar_fn)
        print(f"{tar_fn} removed.")


if __name__ == "__main__":
    main()
