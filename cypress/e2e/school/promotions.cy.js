import config from "../../../src/config";

describe("Promotions", () => {
  it("intercept request of promotions", () => {

    // intercept any request of /v2/school/promotion
    cy.intercept('POST', `${config.v3_graph}`, (req) => {
      if (req.body.operationName === 'GetPromotions') {
        req.alias = 'GetPromotions';
      }
    }).as('promotion');
    cy.visit("/school");

    // check if body exist and if each element of it contains rights properties
    cy.wait("@promotion").then(({ response }) => {
      expect(response.statusCode).to.eq(200);
      expect(response.body).to.exist;

      expect(response.body).to.have.property('data');

      // check each properties expected
      response.body.data.promotions.forEach((el) => {
        expect(el).to.have.property('id');
        expect(el).to.have.property('name');
        expect(el).to.have.property('startingYear');
        expect(el).to.have.property('endingYear');
      });
    });
  });
});
