# Development Guidelines

## Code Quality Tools

### Ansible Lint

We use Ansible Lint to ensure consistent code quality and best practices in our Ansible roles and playbooks.

#### Installation

```bash
pip install ansible-lint
```

#### Usage

Run the linter from the ansible directory:

```bash
cd ansible
ansible-lint
```

#### Configuration

The project includes a custom configuration file for Ansible Lint:

```yaml
# .ansible-lint configuration
skip_list:
  - '301' # Commands should not change things if nothing needs doing
  - 'yaml' # Violations reported by yamllint
  - 'risky-shell-pipe' # Certain shell operations are necessary

warn_list:
  - 'experimental' # Experimental features
  - 'no-changed-when' # Commands should declare changed_when

kinds:
  - playbook: 'playbooks/*.yml'
  - tasks: '**/tasks/*.yml'
  - vars: '**/vars/*.yml'
  - meta: '**/meta/main.yml'
```

#### Pre-commit Integration

Ansible Lint is integrated with pre-commit hooks to automatically check your code before each commit.

#### CI/CD Integration

The linting process runs automatically in the CI/CD pipeline to ensure all merged code adheres to the project's standards.
