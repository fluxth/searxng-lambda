describe("search", () => {
  it("respond to search path", () => {
    cy.visit("/search");
  });

  it("respond to search path with GET query", () => {
    cy.visit({
      url: "/search",
      qs: {
        q: "test",
      },
    });
  });
});
