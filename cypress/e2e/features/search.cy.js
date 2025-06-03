import config from "../../../src/config";

describe("Explore the search feature which result artworks", () => {
  context("Test in home page", () => {
    function testSearch(search, type) {
      cy.get(search).type(type);

      cy.wait("@GetArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
      });

      cy.get('[data-test="nav-link"] > .link').last().click();

      cy.location().should((loc) => {
        // for artist or artwork, need to find a way to conditional with cypress
        expect(loc.pathname).to.match(/art/);
      });
    }

    it("expect to work in home", () => {
      cy.viewport(1280, 720);

      cy.intercept('POST', `${config.v3_graph}`, (req) => {
        if (req.body.operationName === 'GetArtworks') {
          req.alias = 'GetArtworks';
        }
      }).as('GetArtworks');

      cy.visit("/");

      testSearch('[data-test="search"]', "mer");
    });

    it("expect to work in others pages", () => {
      cy.viewport(1280, 720);

      cy.intercept('POST', `${config.v3_graph}`, (req) => {
        if (req.body.operationName === 'GetArtworks') {
          req.alias = 'GetArtworks';
        }
      }).as('GetArtworks');
      cy.visit("/");

      cy.get('[data-test="nav-link"] > .link').first().click();
      testSearch("#search", "cou");

      cy.get('[data-test="nav-link"] > .link').last().click();
      testSearch("#search", "deh");
    });
  });
});
