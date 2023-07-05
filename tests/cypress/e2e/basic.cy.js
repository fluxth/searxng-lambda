describe("basic sanity checks", () => {
  it("respond to healthcheck endpoint", () => {
    cy.request("/healthz").its("body").should("equal", "OK");
  });

  it("respond to root path", () => {
    cy.visit("/");
  });
});
