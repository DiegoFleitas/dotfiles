# subprocess-based behavioral tests for run_once_*.sh (see test/check_*_prereqs.bats).
# Explicit env + timeouts; avoids Bats `run` capture path for the same scenarios.

from __future__ import annotations

import shutil
import subprocess
import textwrap
from pathlib import Path

import pytest

RUN_TIMEOUT = 90


def load_versions_env(repo: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    p = repo / "versions.env"
    for line in p.read_text().splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, _, v = s.partition("=")
        out[k.strip()] = v.strip()
    return out


def write_stub(bin_dir: Path, name: str, content: str) -> None:
    p = bin_dir / name
    p.write_text(textwrap.dedent(content).lstrip("\n"), encoding="utf-8")
    p.chmod(0o755)


def run_script_clean(
    script: Path,
    *,
    home: str,
    path: str,
    call_log: str,
    extra_env: dict[str, str] | None = None,
    timeout: int = RUN_TIMEOUT,
) -> subprocess.CompletedProcess[str]:
    env = {
        "HOME": home,
        "PATH": path,
        "DOTFILES_BREW_USE_PATH_ONLY": "1",
        "DOTFILES_DISABLE_APT": "1",
        "CALL_LOG": call_log,
        "LANG": "C",
        "LC_ALL": "C",
    }
    if extra_env:
        env.update(extra_env)
    return subprocess.run(
        ["/usr/bin/bash", "--noprofile", "--norc", str(script)],
        env=env,
        cwd=script.parent,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def test_after_prereqs_brew_bundle_failure_aborts(repo_root: Path, tmp_path: Path) -> None:
    """Mirrors test/check_after_prereqs.bats first test."""
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".oh-my-zsh").mkdir(parents=True)
    (home / ".bun" / "bin").mkdir(parents=True)
    bun_bin = home / ".bun" / "bin" / "bun"
    bun_bin.write_text("#!/bin/bash\n", encoding="utf-8")
    bun_bin.chmod(0o755)

    (home / ".nvm").mkdir(parents=True)
    (home / ".nvm" / "nvm.sh").write_text("# stub nvm.sh\n", encoding="utf-8")
    (home / ".bashrc").write_text("", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(
        bin_dir,
        "uname",
        """\
        #!/bin/bash
        echo "Linux"
        """,
    )
    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "id",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
        echo 1000
        """,
    )
    for n in ("git", "curl"):
        write_stub(bin_dir, n, "#!/bin/bash\nexit 0\n")
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        case "${{1:-}}" in
          shellenv) exit 0 ;;
          bundle) exit 1 ;;
          *) exit 0 ;;
        esac
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        """\
        #!/bin/bash
        if [ "${1:-}" = "versions" ]; then printf "%s\\n" "* 3.12.0"; exit 0; fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
          pattern="${2:-}"
          input="$(cat)"
          case "${input}" in *"${pattern}"*) exit 0 ;; *) exit 1 ;; esac
        fi
        exit 1
        """,
    )
    for n in ("python3", "wget", "zsh", "chsh"):
        write_stub(bin_dir, n, "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "sudo", "#!/bin/bash\nexit 98\n")

    path = f"{bin_dir}:/bin:/usr/bin"
    target = repo_root / "run_once_after_prereqs.sh"
    cp = run_script_clean(target, home=str(home), path=path, call_log=call_log)
    assert cp.returncode != 0
    assert "brew bundle" in Path(call_log).read_text()


def test_after_prereqs_bun_installer_curl_logged(repo_root: Path, tmp_path: Path) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".oh-my-zsh").mkdir(parents=True)
    (home / ".nvm").mkdir()
    (home / ".nvm" / "nvm.sh").write_text("# stub\n", encoding="utf-8")
    (home / ".bashrc").write_text("", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(bin_dir, "uname", '#!/bin/bash\necho "Linux"\n')
    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "id",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
        echo 1000
        """,
    )
    write_stub(bin_dir, "git", "#!/bin/bash\nexit 0\n")
    write_stub(
        bin_dir,
        "curl",
        f"""\
        #!/bin/bash
        echo "curl $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        case "${{1:-}}" in shellenv|bundle|install) exit 0 ;; esac
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        """\
        #!/bin/bash
        if [ "${1:-}" = "versions" ]; then printf "%s\\n" "* 3.12.0"; exit 0; fi
        exit 0
        """,
    )
    write_stub(bin_dir, "grep", "#!/bin/bash\nexit 1\n")
    for n in ("python3", "wget", "zsh", "chsh"):
        write_stub(bin_dir, n, "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "sudo", "#!/bin/bash\nexit 98\n")
    write_stub(
        bin_dir,
        "bash",
        """\
        #!/bin/bash
        exec /usr/bin/bash "$@"
        """,
    )

    if (home / ".bun").exists():
        shutil.rmtree(home / ".bun")

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_after_prereqs.sh",
        home=str(home),
        path=path,
        call_log=call_log,
    )
    assert cp.returncode == 0
    log = Path(call_log).read_text()
    assert "curl -fsSL https://bun.com/install" in log


def test_after_prereqs_bundle_before_flyctl(repo_root: Path, tmp_path: Path) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".oh-my-zsh").mkdir(parents=True)
    (home / ".bun" / "bin").mkdir(parents=True)
    (home / ".bun" / "bin" / "bun").write_text("#!/bin/bash\n", encoding="utf-8")
    (home / ".bun" / "bin" / "bun").chmod(0o755)
    (home / ".nvm").mkdir(parents=True)
    (home / ".nvm" / "nvm.sh").write_text("# stub\n", encoding="utf-8")
    (home / ".bashrc").write_text("", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(bin_dir, "uname", '#!/bin/bash\necho Linux\n')
    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "id",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
        echo 1000
        """,
    )
    write_stub(bin_dir, "git", "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "curl", "#!/bin/bash\nexit 0\n")
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        case "${{1:-}}" in shellenv|bundle|install) exit 0 ;; esac
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        """\
        #!/bin/bash
        if [ "${1:-}" = "versions" ]; then printf "%s\\n" "* 3.12.0"; exit 0; fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
          pattern="${2:-}"
          input="$(cat)"
          case "${input}" in *"${pattern}"*) exit 0 ;; *) exit 1 ;; esac
        fi
        exit 2
        """,
    )
    for n in ("python3", "wget", "zsh", "chsh"):
        write_stub(bin_dir, n, "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "sudo", "#!/bin/bash\nexit 98\n")
    write_stub(
        bin_dir,
        "bash",
        """\
        #!/bin/bash
        exec /usr/bin/bash "$@"
        """,
    )

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_after_prereqs.sh",
        home=str(home),
        path=path,
        call_log=call_log,
        extra_env={"DOTFILES_INSTALL_FLYCTL": "1"},
    )
    assert cp.returncode == 0
    lines = Path(call_log).read_text().splitlines()
    bundle_i = next(i for i, ln in enumerate(lines) if "brew bundle" in ln)
    fly_i = next(i for i, ln in enumerate(lines) if "brew install flyctl" in ln)
    assert bundle_i < fly_i


def test_after_prereqs_python_message(repo_root: Path, tmp_path: Path) -> None:
    versions = load_versions_env(repo_root)
    pv = versions["PYTHON_VERSION"]

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".oh-my-zsh").mkdir(parents=True)
    (home / ".bun" / "bin").mkdir(parents=True)
    (home / ".bun" / "bin" / "bun").write_text("#!/bin/bash\n", encoding="utf-8")
    (home / ".bun" / "bin" / "bun").chmod(0o755)
    (home / ".nvm").mkdir(parents=True)
    (home / ".nvm" / "nvm.sh").write_text("# stub\n", encoding="utf-8")
    (home / ".bashrc").write_text("", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(bin_dir, "uname", '#!/bin/bash\necho Linux\n')
    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "id",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
        echo 1000
        """,
    )
    write_stub(bin_dir, "git", "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "curl", "#!/bin/bash\nexit 0\n")
    write_stub(
        bin_dir,
        "brew",
        """\
        #!/bin/bash
        case "${1:-}" in shellenv|bundle|install) exit 0 ;; esac
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        r"""\
        #!/bin/bash
        if [ "${1:-}" = "versions" ]; then printf '%s\n' '* 3.11.9'; exit 0; fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        """\
        #!/bin/bash
        if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
          pattern="${2:-}"
          input="$(cat)"
          case "${input}" in *"${pattern}"*) exit 0 ;; *) exit 1 ;; esac
        fi
        exit 2
        """,
    )
    for n in ("python3", "wget", "zsh", "chsh"):
        write_stub(bin_dir, n, "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "sudo", "#!/bin/bash\nexit 98\n")
    write_stub(
        bin_dir,
        "bash",
        """\
        #!/bin/bash
        exec /usr/bin/bash "$@"
        """,
    )

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_after_prereqs.sh",
        home=str(home),
        path=path,
        call_log=call_log,
    )
    assert cp.returncode == 0
    assert f"Installing Python {pv}" in (cp.stdout + cp.stderr)


def test_before_finalize_wsl_skips_chsh(repo_root: Path, tmp_path: Path) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".nvm").mkdir()
    (home / ".nvm" / "nvm.sh").write_text("nvm() { return 0; }\n", encoding="utf-8")
    (home / ".oh-my-zsh").mkdir()
    (home / ".oh-my-zsh" / "oh-my-zsh.sh").write_text("omz() { return 0; }\n", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "zsh",
        f"""\
        #!/bin/bash
        echo "zsh $*" >>"{call_log}"
        if [[ "${{1:-}}" == "-f" ]] && [[ "${{2:-}}" == "-c" ]]; then
          export ZSH="$HOME/.oh-my-zsh"
          [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
          command -v omz >/dev/null 2>&1 && omz update
        fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        f"""\
        #!/bin/bash
        echo "grep $*" >>"{call_log}"
        if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 0; fi
        if [[ "$*" == */etc/shells ]]; then exit 1; fi
        if [[ "${{1:-}}" == "-Eq" ]]; then exit 0; fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "sudo",
        f"""\
        #!/bin/bash
        cat >/dev/null 2>&1 || true
        echo "sudo $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        f"""\
        #!/bin/bash
        echo "pyenv $*" >>"{call_log}"
        if [[ "${{1:-}}" == "versions" ]] && [[ "${{2:-}}" == "--bare" ]]; then
          echo "3.12.0"
          exit 0
        fi
        exit 0
        """,
    )

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_before_finalize.sh",
        home=str(home),
        path=path,
        call_log=call_log,
        extra_env={"SHELL": "/bin/bash"},
    )
    assert cp.returncode == 0
    assert "WSL detected. Skipping chsh" in (cp.stdout + cp.stderr)
    assert "chsh -s" not in Path(call_log).read_text()


def test_before_finalize_chsh_when_not_wsl(repo_root: Path, tmp_path: Path) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".nvm").mkdir()
    (home / ".nvm" / "nvm.sh").write_text("nvm() { return 0; }\n", encoding="utf-8")
    (home / ".oh-my-zsh").mkdir()
    (home / ".oh-my-zsh" / "oh-my-zsh.sh").write_text("omz() { return 0; }\n", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "zsh",
        f"""\
        #!/bin/bash
        echo "zsh $*" >>"{call_log}"
        if [[ "${{1:-}}" == "-f" ]] && [[ "${{2:-}}" == "-c" ]]; then
          export ZSH="$HOME/.oh-my-zsh"
          [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
          command -v omz >/dev/null 2>&1 && omz update
        fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        f"""\
        #!/bin/bash
        echo "grep $*" >>"{call_log}"
        if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 1; fi
        if [[ "$*" == */etc/shells ]]; then exit 1; fi
        if [[ "${{1:-}}" == "-Eq" ]]; then exit 0; fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "sudo",
        f"""\
        #!/bin/bash
        cat >/dev/null 2>&1 || true
        echo "sudo $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "chsh",
        f"""\
        #!/bin/bash
        echo "chsh $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        f"""\
        #!/bin/bash
        echo "pyenv $*" >>"{call_log}"
        if [[ "${{1:-}}" == "versions" ]] && [[ "${{2:-}}" == "--bare" ]]; then
          echo "3.12.0"
          exit 0
        fi
        exit 0
        """,
    )

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_before_finalize.sh",
        home=str(home),
        path=path,
        call_log=call_log,
        extra_env={"SHELL": "/bin/bash"},
    )
    assert cp.returncode == 0
    assert "chsh -s" in Path(call_log).read_text()


def test_before_finalize_skips_brew_upgrade_by_default(repo_root: Path, tmp_path: Path) -> None:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    home = tmp_path / "home"
    (home / ".nvm").mkdir()
    (home / ".nvm" / "nvm.sh").write_text("nvm() { return 0; }\n", encoding="utf-8")
    (home / ".oh-my-zsh").mkdir()
    (home / ".oh-my-zsh" / "oh-my-zsh.sh").write_text("omz() { return 0; }\n", encoding="utf-8")

    call_log = str(tmp_path / "calls.log")
    Path(call_log).write_text("", encoding="utf-8")

    write_stub(
        bin_dir,
        "dirname",
        """\
        #!/bin/bash
        path="${1:-}"
        path="${path%/}"
        if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
        """,
    )
    write_stub(
        bin_dir,
        "zsh",
        """\
        #!/bin/bash
        if [[ "${1:-}" == "-f" ]] && [[ "${2:-}" == "-c" ]]; then
          export ZSH="$HOME/.oh-my-zsh"
          [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
          command -v omz >/dev/null 2>&1 && omz update
        fi
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "grep",
        """\
        #!/bin/bash
        if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 1; fi
        if [[ "$*" == */etc/shells ]]; then exit 1; fi
        if [[ "${1:-}" == "-Eq" ]]; then exit 0; fi
        exit 0
        """,
    )
    write_stub(bin_dir, "sudo", "#!/bin/bash\nexit 0\n")
    write_stub(bin_dir, "chsh", "#!/bin/bash\nexit 0\n")
    write_stub(
        bin_dir,
        "brew",
        f"""\
        #!/bin/bash
        echo "brew $*" >>"{call_log}"
        exit 0
        """,
    )
    write_stub(
        bin_dir,
        "pyenv",
        """\
        #!/bin/bash
        if [[ "${1:-}" == "versions" ]] && [[ "${2:-}" == "--bare" ]]; then
          echo "3.12.0"
          exit 0
        fi
        exit 0
        """,
    )

    path = f"{bin_dir}:/bin:/usr/bin"
    cp = run_script_clean(
        repo_root / "run_once_before_finalize.sh",
        home=str(home),
        path=path,
        call_log=call_log,
        extra_env={"SHELL": "/bin/bash"},
    )
    assert cp.returncode == 0
    assert "Skipping brew upgrade by default" in (cp.stdout + cp.stderr)
