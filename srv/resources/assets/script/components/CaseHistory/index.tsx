import {h, FunctionalComponent} from "preact"
import {Case} from './Case'
import {HistoryItem} from '../types'

type F<T> = FunctionalComponent<T>

type Props = {
  caseHistory: () => HistoryItem[]
}

export const CaseHistory: F<Props> = ({caseHistory}) =>
  <section>
    <h4 style='float: left'>История по кейсу</h4>
    <div style='float: right'>иконки</div>
    <div id='case-history'>
      {caseHistory().map( data => <Case caseData={data}/>)}
    </div>
  </section>

