import config from "../../../src/config";

describe("Students", () => {
  it("intercept request of students", () => {

    cy.visit("/school");

    cy.get(".promo__link").last().click();

    // intercept students request
    cy.intercept('POST', `${config.v3_graph}`, (req) => {
      if (req.body.operationName === 'GetStudents') {
        req.alias = 'GetStudents';
      }
    }).as('students');

    cy.wait("@students").then(({ response }) => {
      expect(response.statusCode).to.eq(200);
      expect(response.body).to.exist;

      expect(response.body).to.have.property('data');

      // check each properties expected
      response.body.data.promotion.students.forEach((el) => {
        expect(el).to.have.property('photo');
        expect(el).to.have.property('displayName');
        expect(el.artist).to.have.property('id');
        expect(el.user).to.have.property('id');
      });
    });
  });
});
