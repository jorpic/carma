import {h, FunctionalComponent} from 'preact'

type F<T> = FunctionalComponent<T>

type Props = {
  commenttext: string
}

export const CaseCustomerFeedback: F<Props> = ({commenttext}) => {
  return (
    <div>
      <b>Комментарий: </b>
      {commenttext}
    </div>
  )
}
