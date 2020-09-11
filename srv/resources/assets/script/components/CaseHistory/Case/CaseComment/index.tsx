import {h, FunctionalComponent} from 'preact'

type F<T> = FunctionalComponent<T>

type Props = {
  commenttext: string
}

export const CaseComment: F<Props> = ({commenttext}) => {
  return <div class='comment'><b>Комментарий: </b>{commenttext}</div>
}
