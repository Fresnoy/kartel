import config from "../../../src/config";

describe("Artist and artworks informations from school, navigate through all pages like branch", () => {
  context("Check navigation Home to School", () => {
    it("Home logo redirect should be '/'", () => {
      cy.viewport(1280, 720);
      cy.visit("/");

      // check if the logo redirect to "/"
      cy.get("[data-test='logo-lg']").click();
      cy.location().should((loc) => {
        expect(loc.pathname).to.eq("/");
      });
    });

    it("Navigation bar to School with link", () => {
      cy.viewport(1280, 720);
      cy.visit("/");

      // check if the first navbar link which is "school" redirect to "/school/promotion/29"
      cy.get("[data-test='nav-link']").contains("School").click();
      cy.location().should((loc) => {
        expect(loc.pathname).to.eq("/school/promotion/29");
      });
    });
  });

  context("Check navigation School to an artist profile", () => {
    it("Get data of differents promotions", () => {
      cy.viewport(1280, 720);

      // setup the interception of promotion request
      cy.intercept('POST', `${config.v3_graph}`, (req) => {
              if (req.body.operationName === 'GetPromotions') {
                req.alias = 'GetPromotions';
              }
            }).as('GetPromotions');

      cy.visit("/school");

      // wait the request intercepted @promotions declared before and check is body properties
      cy.wait("@GetPromotions").then(({ response }) => {
        expect(response.statusCode).to.eq(200);
        expect(response.body).to.exist;

        expect(response.body).to.have.property('data');

        // check all promotions properties expected
        response.body.data.promotions.forEach((el) => {
          expect(el).to.have.property('id');
          expect(el).to.have.property('name');
          expect(el).to.have.property('startingYear');
          expect(el).to.have.property('endingYear');
        });
      });

      cy.get(":nth-child(5) > .promo__link").click();
    });

    it("Get a student from a promotion", () => {
      cy.viewport(1280, 720);
      cy.visit("/school");

      cy.get(":nth-child(8) > .promo__link").click();

      cy.get('[data-key="0"] > .relative').click();

      // check if the click before redirect to an artist page
      cy.location().should((loc) => {
        expect(loc.pathname).to.match(/artist/);
      });
    });
  });

  context("Artist profile to artwork", () => {
    it("Check data of artist page 1606", () => {
      cy.viewport(1280, 720);
      cy.visit("/artist/1606");

      // check if the page have the good artist
      cy.get("h2").contains("Amélie Agbo");
      cy.get("h2").contains("Œuvres");
    });

    it("Check data of an artwork of the precedent artist", () => {
      cy.viewport(1280, 720);

      cy.visit("/artwork/1278");

      // check if the page have the good artwork
      cy.get("h1").contains("Bénincity : épisode 4");

      // check the artist to
      cy.get("a").contains("Amélie Agbo").click();
      cy.get("h2").contains("Amélie Agbo");
    });
  });
});
