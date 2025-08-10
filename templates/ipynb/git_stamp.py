"""Python script to display git commit information and render time in a Jupyter notebook."""

import re
from datetime import datetime

import git
from IPython.display import Markdown, display


def git_stamp():
    """Display the current git commit hash and timestamp."""

    def remote_https_url(repo):
        try:
            url = next(repo.remote("origin").urls)
        except (ValueError, StopIteration):
            return None

        # Handle SSH form: git@github.com:me/repo(.git)
        m = re.match(r"git@([^:]+):(.+?)(?:\.git)?$", url)
        if m:
            return f"https://{m.group(1)}/{m.group(2)}"

        # Handle https form: strip .git if present
        if url.startswith("http"):
            return url.removesuffix(".git")

        # If not the above formats, return None
        return None

    def offset_str(dt):
        if dt.tzinfo is not None:
            offset_td = dt.tzinfo.utcoffset(dt)
            if offset_td is None:
                return "+0000"
            offset_seconds = int(offset_td.total_seconds())
            sign = "+" if offset_seconds >= 0 else "-"
            hours, remainder = divmod(abs(offset_seconds), 3600)
            minutes, _ = divmod(remainder, 60)
            return f"{sign}{hours:02}{minutes:02}"
        return "+0000"

    def time_str(timestamp):
        if timestamp.tzinfo is None:
            # If the commit time is naive, assume local timezone
            timestamp = timestamp.astimezone()
        return timestamp.strftime("%Y-%m-%d %H:%M:%S") + " " + offset_str(timestamp)

    try:
        repo = git.Repo(".", search_parent_directories=True)
    except (git.InvalidGitRepositoryError, git.NoSuchPathError):
        print("Git not initialized in this directory.")
        return

    # Branch name (handle detached HEAD explicitly)
    if getattr(repo.head, "is_detached", False):
        branch_name = "detached HEAD"
    else:
        branch_name = repo.active_branch.name

    # Get commit hash (truncate to 12 chars) and dirty flag
    short_hash = repo.head.commit.hexsha[:12]
    dirty_flag = "*" if repo.is_dirty(untracked_files=True) else ""
    print("Git commit hash: " + short_hash + dirty_flag + " (" + branch_name + ")")

    # Get commit timestamp
    timestamp = repo.head.commit.committed_datetime  # .astimezone()
    print("Git commit Time: " + time_str(timestamp))

    # Get notebook render timestamp
    render_time = datetime.now().replace(microsecond=0).astimezone()
    print("Notebook render Time: " + time_str(render_time))

    # Note: link will only work if commit has been pushed to the remote repository.
    remote_url = remote_https_url(repo)
    if remote_url:
        display(Markdown(f"<{remote_url}/commit/{short_hash}>"))
    else:
        print("No URL found for remote 'origin'.")
