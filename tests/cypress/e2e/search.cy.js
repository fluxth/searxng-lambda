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

    cy.get("input#q").should("have.value", "test");
    cy.get("div#results article.result").should("exist");
  });

  it("respond to search path with POST query", () => {
    cy.visit({
      url: "/search",
      method: "POST",
      body: {
        q: "test",
      },
    });

    cy.get("input#q").should("have.value", "test");
    cy.get("div#results article.result").should("exist");
  });

  it("respond to general search category", () => {
    cy.visit({
      url: "/search",
      qs: {
        q: "test",
        category_general: "",
      },
    });

    cy.get("input#q").should("have.value", "test");
    cy.get("div#results article.result.result-default").should("exist");
  });

  it("respond to image search category", () => {
    cy.visit({
      url: "/search",
      qs: {
        q: "test",
        category_images: "",
      },
    });

    cy.get("input#q").should("have.value", "test");
    cy.get("div#results article.result.result-images").should("exist");
  });
});
