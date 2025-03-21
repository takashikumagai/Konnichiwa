import pytest
from api.format_bytes import format_bytes


@pytest.mark.parametrize(
    "input, expected",
    [
        (0, "0.00 Bytes"),
        (1024, "1.00 KB"),
        (1024 * 1024, "1.00 MB"),
        (1024 * 1024 * 1024, "1.00 GB"),
        (1024 * 1024 * 1024 * 1024, "1.00 TB"),
        (2048, "2.00 KB"),
        (1536, "1.50 KB"),
        (500, "500.00 Bytes"),
        (2560, "2.50 KB"),
        (10485760, "10.00 MB"),
        (10737418240, "10.00 GB"),
        (10995116277760, "10.00 TB"),
    ],
)
def test_format_bytes(input, expected):
    assert format_bytes(input) == expected
