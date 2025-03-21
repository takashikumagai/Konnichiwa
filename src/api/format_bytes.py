def format_bytes(bytes):
    """Format bytes to human readable format"""
    units = ["Bytes", "KB", "MB", "GB", "TB"]
    unit_index = 0
    value = float(bytes)

    while value >= 1024 and unit_index < len(units) - 1:
        value /= 1024
        unit_index += 1

    return f"{value:.2f} {units[unit_index]}"
