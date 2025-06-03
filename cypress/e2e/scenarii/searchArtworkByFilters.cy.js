import config from "../../../src/config";

describe("Search artworks or an artwork in the artworks page and it's filters", () => {
  context("Check the infinite scrolling", () => {
    beforeEach(() => {
      cy.viewport(1280, 720);

      cy.intercept('POST', `${config.v3_graph}`, (req) => {
        if (req.body.operationName === 'FetchArtworks') {
          req.alias = 'FetchArtworks';
        }
      }).as('FetchArtworks');


      cy.intercept('POST', `${config.v3_graph}`, (req) => {
        if (req.body.operationName === 'FetchArtworks') {
          req.alias = 'FetchArtworks';
        }
      }).as('FetchFilteredArtworks');

      cy.visit("/artworks");
    });

    it("Home logo redirect should be '/'", () => {
      cy.wait("@FetchArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
        cy.scrollTo("bottom");
      });

      // wait a second time for check
      cy.wait("@FetchArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
        cy.scrollTo("bottom");
      });

      cy.get("#date").select(5);

      cy.wait("@FetchFilteredArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
      });
    });
  });

  context("Check if the results have the right production date", () => {
    beforeEach(() => {
      cy.viewport(1280, 720);
      cy.intercept('POST', `${config.v3_graph}`, (req) => {
        if (req.body.operationName === 'FetchArtworks') {
          req.alias = 'FetchArtworks';
        }
      }).as('FetchFilteredYearArtworks');

      cy.visit("/artworks");
    });

    it("", () => {
      cy.get("#date").select(3);

      // check for third option
      cy.wait("@FetchFilteredYearArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
      });

      cy.get("#date").select(5);

      // check for fifth option
      cy.wait("@FetchFilteredYearArtworks").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;
      });

      cy.get(
        ":nth-child(1) > .flex > .bg-gray-extralightest > .w-full"
      ).click();

      // match every time the url change for checking if we stay in the artwork tree
      cy.on("url:changed", (url) => {
        // regex can be more precise to match only artwork with /:id
        // Need to find a way to integrate
        expect(url).to.match(/artwork/);
      });

      cy.get("section:first > .flex-wrap > h3").contains("2022");
    });
  });
});
