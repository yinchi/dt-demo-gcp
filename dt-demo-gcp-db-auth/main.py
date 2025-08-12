"""Test script (hello world)."""

from dt_demo_gcp import auth


def main():
    """Test function.

    Print hello message when script is run via `uv run --package dt-demo-gcp-db-auth main.py`.
    """
    print("Hello from dt-demo-gcp-db-auth!")
    auth.main()


if __name__ == "__main__":
    main()
