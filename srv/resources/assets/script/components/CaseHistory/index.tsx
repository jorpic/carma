import {h, FunctionalComponent } from "preact"


export const CaseHistory = ({data}) =>
  <h4 style="float: left">История кейса: {data().length}</h4>
