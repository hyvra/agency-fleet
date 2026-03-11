# =============================================================================
# agency-fleet — Isolated Claude CLI agent runtime
#
# Contains 112 agent specs from The Agency, running under their own
# Claude CLI config. Zero overlap with host ~/.claude/.
#
# Build:  docker build -t agency-fleet -f docker/Dockerfile .
# Run:    docker compose -f docker/docker-compose.yml up
# Auth:   docker exec -it agency-fleet claude login
# =============================================================================

FROM node:20-slim

# Install Claude CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/bash agency

WORKDIR /home/agency

# Copy agent specs into container (as root for flatten step)
COPY engineering/ /home/agency/.claude/agents/engineering/
COPY design/ /home/agency/.claude/agents/design/
COPY marketing/ /home/agency/.claude/agents/marketing/
COPY testing/ /home/agency/.claude/agents/testing/
COPY specialized/ /home/agency/.claude/agents/specialized/
COPY product/ /home/agency/.claude/agents/product/
COPY project-management/ /home/agency/.claude/agents/project-management/
COPY support/ /home/agency/.claude/agents/support/
COPY spatial-computing/ /home/agency/.claude/agents/spatial-computing/
COPY paid-media/ /home/agency/.claude/agents/paid-media/
COPY game-development/ /home/agency/.claude/agents/game-development/

# Copy container-specific Claude config (NOT host config)
COPY docker/.claude-container/settings.json /home/agency/.claude/settings.json
COPY docker/.claude-container/CLAUDE.md /home/agency/.claude/CLAUDE.md

# Copy orchestrator
COPY docker/entrypoint.sh /home/agency/entrypoint.sh

# Flatten agent specs into .claude/agents/ (Claude Code expects flat directory)
# Done as root to avoid permission issues with cross-directory mv
RUN find /home/agency/.claude/agents/ -mindepth 2 -name '*.md' -exec mv {} /home/agency/.claude/agents/ \; && \
    find /home/agency/.claude/agents/ -type d -empty -delete

# Create workspace and fix ownership
RUN mkdir -p /home/agency/workspace && \
    chown -R agency:agency /home/agency

# Switch to non-root user
USER agency

ENV HOME=/home/agency
ENV NODE_ENV=production

EXPOSE 7890

ENTRYPOINT ["/bin/bash", "/home/agency/entrypoint.sh"]
