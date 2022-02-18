Uhh, I actually have no idea how the whole contributing process on GitHub works, so if you want to contribute to this repo you will first have to explain the process to me (〜￣▽￣)〜. I don't even know what to write here. I guess I can give you some info about branches and stuff:

There are currently 3 branches in this repo:
- `dev` is where I frequently upload code while working on the app, don't worry about this branch
- `beta` is a relatively stable branch, it has the newest features and is likely to actually work, unlike the `dev` branch
- `main` is the stable branch

Making a [pull request to `main`](../../compare/main...beta?expand=1&template=main_branch.md) should only be done from `beta`, and by me (for now, at least). There is a [checklist](.github/PULL_REQUEST_TEMPLATE/main_branch.md) that should be completed before doing so.

Making pull requests to `beta` is allowed for anyone, I guess? Just follow this [template](.github/PULL_REQUEST_TEMPLATE/beta_branch.md) if you want to do it (append `&template=beta_branch.md` to the url when creating a pull request).
