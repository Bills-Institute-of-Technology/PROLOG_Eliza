---
# Git Workflow: Branching and Syncing
---
This guide provides basic instructions for creating feature branches and syncing with the remote repository throughout the lifecycle of a single update.

## 1. Create a New Branch

Implement changes in branches:

- Isolate features or experiments
- Avoid breaking `main`
- Enable clean pull requests and code reviews

```sh
git checkout -b feature/<branch-name>
git push -u origin feature/<branch-name>
```

- Creates and switches to a new branch called `feature/<branch-name>`.
- Pushes the new local branch to the remote for:
    - **Visibility:** Others can see your work and provide feedback.
    - **Backup:** Your work is safe if your local environment crashes.
    - **CI/CD Triggers:** Some setups run tests/linters on every pushed branch.
- **Caution:**
    - For public repos or strict review policies, prefix with `wip/` or `draft/` to signal it's not ready.
    - Avoid pushing broken code unless the team is aware it's exploratory.

---

## 2. Work Locally and Push Updates

Do your work locally, then stage, commit, and push changes:

```sh
git add .
git commit -m "<short description of change>"
git push -u origin feature/<branch-name>
```

- Stages and commits local changes with a descriptive comment.
- Pushes updates to the remote branch and sets upstream tracking.

---

## 3. Create Pull Request and Merge to Main

In your GitHub repository (online):

- Go to your GitHub repo
- Click **Compare & Pull Request**
- Add a title and description
- Submit the PR to merge into `main`

---

## 4. Sync Local After Merge

Once the pull request is approved and code is merged:

```sh
git checkout main
git pull
```

- Switch to `main`, pull the latest changes.

---

## 5. (Optional) Delete Local/Remote Branch

```sh
git branch -d feature/<branch-name>
git push origin --delete feature/<branch-name>
```

- These commands are used to remove completed branches when work is done
- The PULL REQUEST / MERGE can optionally delete the remote branch when merge is complete
- Use these commands to delete the local branch
- You can delete the remote branch here if it was not deleted with the PULL/MERGE
