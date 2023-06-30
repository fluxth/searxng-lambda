const fs = require("fs");

module.exports = async ({ github, context, inputs }) => {
  const releaseContent = fs.readFileSync(".github/RELEASE_BODY.md", "utf8");

  const { data: releases } = await github.rest.repos.listReleases({
    owner: context.repo.owner,
    repo: context.repo.repo,
    per_page: 100,
  });

  const release = releases
    .filter((r) => r.draft)
    .filter((r) => r.tag_name === inputs.nextVersion)[0];

  const releasePayload = {
    owner: context.repo.owner,
    repo: context.repo.repo,
    draft: true,
    body: releaseContent,
    name: inputs.nextVersion,
    target_commitish: inputs.sha,
    tag_name: inputs.nextVersion,
  };

  if (release) {
    // update
    await github.rest.repos.updateRelease({
      release_id: release.id,
      ...releasePayload,
    });
  } else {
    // create
    await github.rest.repos.createRelease({
      make_latest: "true",
      ...releasePayload,
    });
  }
};
