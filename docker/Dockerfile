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

# Set up isolated .claude config
USER agency
WORKDIR /home/agency

# Copy agent specs into container — one COPY per division directory
COPY --chown=agency:agency engineering/ /home/agency/.claude/agents/engineering/
COPY --chown=agency:agency design/ /home/agency/.claude/agents/design/
COPY --chown=agency:agency marketing/ /home/agency/.claude/agents/marketing/
COPY --chown=agency:agency testing/ /home/agency/.claude/agents/testing/
COPY --chown=agency:agency specialized/ /home/agency/.claude/agents/specialized/
COPY --chown=agency:agency product/ /home/agency/.claude/agents/product/
COPY --chown=agency:agency project-management/ /home/agency/.claude/agents/project-management/
COPY --chown=agency:agency support/ /home/agency/.claude/agents/support/
COPY --chown=agency:agency spatial-computing/ /home/agency/.claude/agents/spatial-computing/
COPY --chown=agency:agency paid-media/ /home/agency/.claude/agents/paid-media/
COPY --chown=agency:agency game-development/ /home/agency/.claude/agents/game-development/

# Copy container-specific Claude config (NOT host config)
COPY --chown=agency:agency docker/.claude-container/settings.json /home/agency/.claude/settings.json
COPY --chown=agency:agency docker/.claude-container/CLAUDE.md /home/agency/.claude/CLAUDE.md

# Copy orchestrator
COPY --chown=agency:agency docker/entrypoint.sh /home/agency/entrypoint.sh

# Flatten agent specs into .claude/agents/ (Claude Code expects flat directory)
RUN find /home/agency/.claude/agents/ -mindepth 2 -name '*.md' -exec mv {} /home/agency/.claude/agents/ \; && \
    find /home/agency/.claude/agents/ -type d -empty -delete

# Create workspace for agent execution
RUN mkdir -p /home/agency/workspace

ENV HOME=/home/agency
ENV NODE_ENV=production

EXPOSE 7890

ENTRYPOINT ["/bin/bash", "/home/agency/entrypoint.sh"]
